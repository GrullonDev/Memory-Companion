import 'dart:math' as math;

import 'package:memory_companion/features/player/model/player_streak.dart';

/// What the surprise chest adds on top of a day's reward.
enum ChestBonus { coins, xp }

/// One day's reward: the base, scaled by the streak multiplier, and every
/// [DailyRewardSchedule.chestEvery] days a surprise chest on top.
class DailyReward {
  const DailyReward({
    required this.day,
    required this.multiplier,
    required this.coins,
    required this.xp,
    this.chestBonus,
    this.chestAmount = 0,
  });

  /// The streak day this reward is for, from 1.
  final int day;
  final double multiplier;

  /// Coins and XP before the chest.
  final int coins;
  final int xp;

  /// The chest's surprise, on chest days.
  final ChestBonus? chestBonus;
  final int chestAmount;

  bool get isChestDay => chestBonus != null;

  int get totalCoins =>
      coins + (chestBonus == ChestBonus.coins ? chestAmount : 0);
  int get totalXp => xp + (chestBonus == ChestBonus.xp ? chestAmount : 0);
}

/// The rules of the daily reward, as pure functions so every case can be
/// tested without a database.
abstract final class DailyRewardSchedule {
  static const baseCoins = 20;
  static const baseXp = 10;

  /// The multiplier grows by this much per consecutive day...
  static const multiplierStep = 0.25;

  /// ...up to this, reached on day 9. A cap keeps a long streak rewarding
  /// without letting it outgrow what a match pays.
  static const maxMultiplier = 3.0;

  /// A surprise chest every week of streak.
  static const chestEvery = 7;

  static double multiplierFor(int day) =>
      math.min(1 + multiplierStep * (math.max(day, 1) - 1), maxMultiplier);

  /// The reward for streak [day]. [dateKey] seeds the chest's surprise, so
  /// reopening the modal, or the app, never rerolls it.
  static DailyReward rewardFor(int day, {required String dateKey}) {
    final multiplier = multiplierFor(day);
    final chest = day > 0 && day % chestEvery == 0;
    ChestBonus? bonus;
    var amount = 0;
    if (chest) {
      final random = math.Random(_stableHash(dateKey));
      bonus = random.nextBool() ? ChestBonus.coins : ChestBonus.xp;
      amount = switch (bonus) {
        ChestBonus.coins => 50 + random.nextInt(4) * 25, // 50–125
        ChestBonus.xp => 30 + random.nextInt(4) * 15, // 30–75
      };
    }
    return DailyReward(
      day: day,
      multiplier: multiplier,
      coins: (baseCoins * multiplier).round(),
      xp: (baseXp * multiplier).round(),
      chestBonus: bonus,
      chestAmount: amount,
    );
  }

  /// `String.hashCode` is not promised to stay the same between runs.
  static int _stableHash(String value) {
    var hash = 17;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return hash;
  }
}

/// Where the player stands with today's reward.
class DailyRewardStatus {
  const DailyRewardStatus({
    required this.available,
    required this.streak,
    required this.reward,
    required this.todayKey,
  });

  /// Resolves the status from what `daily_rewards` stores, at [now].
  ///
  /// Reuses [advanceStreak], so the claim streak follows the same rules as
  /// the play streak: a missed day starts over at 1, crossing a time zone
  /// never breaks it, and moving the clock back grants nothing.
  factory DailyRewardStatus.resolve({
    required String? lastClaimDate,
    required int claimStreak,
    required DateTime now,
  }) {
    final next = advanceStreak(
      lastPlayedDate: lastClaimDate,
      currentStreak: claimStreak,
      longestStreak: 0,
      now: now,
    );
    final todayKey = localDateKey(now);
    if (next.changed) {
      return DailyRewardStatus(
        available: true,
        streak: next.currentStreak,
        reward: DailyRewardSchedule.rewardFor(
          next.currentStreak,
          dateKey: todayKey,
        ),
        todayKey: todayKey,
      );
    }
    // Claimed already: show what tomorrow holds, to bring the player back.
    final tomorrow = localDateKey(DateTime(now.year, now.month, now.day + 1));
    return DailyRewardStatus(
      available: false,
      streak: claimStreak,
      reward: DailyRewardSchedule.rewardFor(claimStreak + 1, dateKey: tomorrow),
      todayKey: todayKey,
    );
  }

  /// Whether today's reward is waiting to be claimed.
  final bool available;

  /// The streak once today's reward is claimed: the day being offered when
  /// [available], the streak already reached otherwise.
  final int streak;

  /// Today's reward when [available]; tomorrow's otherwise.
  final DailyReward reward;
  final String todayKey;

  /// The streak days in the current week of the track, 1-based.
  List<int> get weekDays {
    final current = available ? streak : streak + 1;
    final start =
        ((current - 1) ~/ DailyRewardSchedule.chestEvery) *
            DailyRewardSchedule.chestEvery +
        1;
    return [for (var i = 0; i < DailyRewardSchedule.chestEvery; i++) start + i];
  }
}

/// What a claim paid out.
class DailyRewardClaim {
  const DailyRewardClaim({required this.reward, required this.streak});

  final DailyReward reward;
  final int streak;
}
