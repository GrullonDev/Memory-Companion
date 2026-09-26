import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_result.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_streak.dart';

/// Today's result, if any, and the streak it belongs to.
class DailyStatus {
  const DailyStatus({required this.today, required this.streak});

  static const empty = DailyStatus(today: null, streak: DailyStreak.empty);

  /// Null until today's challenge is completed.
  final DailyResult? today;
  final DailyStreak streak;

  bool get completedToday => today != null;
}

/// Reads and writes daily challenge results in the local database.
///
/// Offline by construction: the challenge itself comes from the date, and
/// the result lands in SQLite. Rows are left `pending` for the sync engine,
/// which can push them whenever a connection appears.
class DailyChallengeRepository {
  DailyChallengeRepository({
    required AppDatabase database,
    DateTime Function()? clock,
  }) : _db = database,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Stores a finished challenge. Returns false, and changes nothing, if
  /// this day was already completed: only the first attempt counts, or the
  /// board — the same for everyone — could be replayed from memory for a
  /// better score.
  Future<bool> saveResult({
    required String playerId,
    required DailyResult result,
  }) {
    return _db.transaction(() async {
      final existing =
          await (_db.select(_db.dailyChallengeProgress)..where(
                (p) =>
                    p.playerLocalId.equals(playerId) &
                    p.challengeId.equals(result.dateKey),
              ))
              .getSingleOrNull();
      if (existing != null && existing.completed) return false;

      await _db
          .into(_db.dailyChallengeProgress)
          .insertOnConflictUpdate(
            DailyChallengeProgressCompanion.insert(
              playerLocalId: playerId,
              challengeId: result.dateKey,
              completed: const Value(true),
              score: Value(result.score),
              completedAt: Value(_now().millisecondsSinceEpoch),
              moves: Value(result.moves),
              elapsedSeconds: Value(result.elapsedSeconds),
              hintsUsed: Value(result.hintsUsed),
              grid: Value(result.encodedGrid),
              syncStatus: SyncStatus.pending,
            ),
          );
      return true;
    });
  }

  /// Emits today's status and every change after it.
  ///
  /// [dateKey] and [number] identify today; they are passed in rather than
  /// computed here so a screen that stays open past midnight keeps showing
  /// the challenge it was opened for.
  Stream<DailyStatus> watch({
    required String playerId,
    required String dateKey,
    required int number,
  }) {
    final query = _db.select(_db.dailyChallengeProgress)
      ..where(
        (p) => p.playerLocalId.equals(playerId) & p.completed.equals(true),
      );

    return query.watch().map((rows) {
      final todayRow = rows.where((r) => r.challengeId == dateKey).firstOrNull;
      return DailyStatus(
        today: todayRow == null ? null : _resultFrom(todayRow, number),
        streak: DailyStreak.fromDates(rows.map((r) => r.challengeId), dateKey),
      );
    });
  }

  static DailyResult _resultFrom(DailyChallengeProgressRow row, int number) {
    final decoded = DailyResult.decodeGrid(row.grid);
    return DailyResult(
      dateKey: row.challengeId,
      number: number,
      elapsedSeconds: row.elapsedSeconds,
      moves: row.moves,
      hintsUsed: row.hintsUsed,
      score: row.score,
      columns: decoded.columns,
      grid: decoded.grid,
    );
  }
}
