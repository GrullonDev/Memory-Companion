import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/daily_reward/model/daily_reward.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

/// Pays out the daily reward.
///
/// Idempotent like the ladder rewards: the claim date and the coins and XP
/// are written **in one transaction**, so claiming twice — or the app
/// closing halfway — can neither pay a day twice nor mark it paid unpaid.
class DailyRewardRepository {
  DailyRewardRepository({
    required AppDatabase database,
    required PlayerRepository playerRepository,
    DateTime Function()? clock,
  }) : _db = database,
       _playerRepository = playerRepository,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final PlayerRepository _playerRepository;
  final DateTime Function() _now;

  /// [playerLocalId]'s status, recomputed on every change to their row.
  Stream<DailyRewardStatus> watchStatus(String playerLocalId) {
    return _query(
      playerLocalId,
    ).watchSingleOrNull().map((row) => _statusOf(row, _now()));
  }

  /// Claims today's reward. Null if it was already claimed today.
  Future<DailyRewardClaim?> claim({required String playerLocalId}) {
    return _db.transaction(() async {
      final now = _now();
      final row = await _query(playerLocalId).getSingleOrNull();
      final status = _statusOf(row, now);
      if (!status.available) return null;

      final reward = status.reward;
      await _db
          .into(_db.dailyRewards)
          .insertOnConflictUpdate(
            DailyRewardsCompanion.insert(
              playerLocalId: playerLocalId,
              lastClaimDate: Value(status.todayKey),
              claimStreak: Value(status.streak),
              longestClaimStreak: Value(
                status.streak > (row?.longestClaimStreak ?? 0)
                    ? status.streak
                    : row!.longestClaimStreak,
              ),
              totalClaims: Value((row?.totalClaims ?? 0) + 1),
              updatedAt: now.millisecondsSinceEpoch,
            ),
          );
      await _playerRepository.earnCoins(
        localId: playerLocalId,
        amount: reward.totalCoins,
      );
      await _playerRepository.earnXp(
        localId: playerLocalId,
        amount: reward.totalXp,
      );
      return DailyRewardClaim(reward: reward, streak: status.streak);
    });
  }

  SimpleSelectStatement<$DailyRewardsTable, DailyRewardRow> _query(
    String playerLocalId,
  ) =>
      _db.select(_db.dailyRewards)
        ..where((r) => r.playerLocalId.equals(playerLocalId));

  static DailyRewardStatus _statusOf(DailyRewardRow? row, DateTime now) =>
      DailyRewardStatus.resolve(
        lastClaimDate: row?.lastClaimDate,
        claimStreak: row?.claimStreak ?? 0,
        now: now,
      );
}
