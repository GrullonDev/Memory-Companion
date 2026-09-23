import 'dart:math';

import 'package:memory_companion/features/daily_challenge/model/daily_seed.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';

/// One day's challenge: identical for every player on that local date.
///
/// Built entirely from the date, so it needs no download and no server. The
/// board is dealt with [random], the category rotates by day, and the
/// difficulty is fixed — not adaptive — because results are only worth
/// comparing if everyone faced the same board.
class DailyChallenge {
  DailyChallenge._({
    required this.dateKey,
    required this.number,
    required this.category,
    required this.settings,
  });

  factory DailyChallenge.forDate(DateTime now) {
    final key = DailySeed.dateKey(now);
    final local = now.toLocal();
    // Whole days in UTC between two calendar dates: immune to DST shifts,
    // which would make a local-time difference 23 or 25 hours.
    final day = DateTime.utc(local.year, local.month, local.day);
    final number = day.difference(epoch).inDays + 1;

    final categories = GameCategories.all;
    final category = categories[number % categories.length];

    return DailyChallenge._(
      dateKey: key,
      number: number,
      category: category,
      settings: _engine.settingsFor(category, _fixedSkill),
    );
  }

  /// Challenge #1. Shifting it renumbers every challenge, so set it once
  /// (ideally to launch day) and leave it.
  static final DateTime epoch = DateTime.utc(2026, 1, 1);

  static const pairCount = 6;

  /// Coins for the first completion of the day.
  static const rewardCoins = 50;

  static const _engine = AdaptiveDifficulty();

  /// Beginner-friendly but not trivial: gentle content, six pairs, a
  /// generous preview. Tuned for the app's older players, since everyone
  /// gets the same board and nobody should be locked out of the streak.
  static const _fixedSkill = SkillState(skill: 0.3, pairCount: pairCount);

  /// `'YYYY-MM-DD'` in local time. Also the progress row's key.
  final String dateKey;

  /// Public, human number: "Challenge #266".
  final int number;

  final GameCategory category;
  final DifficultySettings settings;

  int get seed => DailySeed.seedFor(dateKey);

  /// A fresh generator every call, so dealing twice deals the same board.
  Random get random => SeededRandom(seed);

  @override
  bool operator ==(Object other) =>
      other is DailyChallenge && other.dateKey == dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}
