import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/model/stats_bucket.dart';

/// What the analytics need from the database, already reduced by SQLite.
///
/// However long the history grows, this stays small: one totals row, one
/// row per day inside the chart window, and one short string per day ever
/// played. No query here returns one row per game.
class StatsSnapshot {
  const StatsSnapshot({
    required this.totals,
    required this.record,
    required this.daily,
    required this.playedDays,
  });

  final StatsBucket totals;
  final RecordGame? record;

  /// Days inside the requested window that have games, oldest first.
  final List<DailyStats> daily;

  /// Every distinct day with a game, newest first. Feeds the streaks.
  final List<String> playedDays;
}

/// Local-only store for per-game metrics. Nothing here touches the network
/// or the sync queue.
class StatsRepository {
  StatsRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  /// The sums every bucket query selects, in [StatsBucket.fromColumns]'s
  /// column names.
  static const _bucketColumns = '''
    COUNT(*) AS games,
    COALESCE(SUM(won), 0) AS wins,
    COALESCE(SUM(matched_pairs), 0) AS matched_pairs,
    COALESCE(SUM(moves), 0) AS moves,
    COALESCE(SUM(memory_errors), 0) AS memory_errors,
    COALESCE(SUM(pair_count), 0) AS pairs,
    COALESCE(SUM(CASE WHEN won = 1 THEN seconds_elapsed END), 0) AS won_seconds,
    COALESCE(SUM(CASE WHEN won = 1 THEN pair_count END), 0) AS won_pairs
  ''';

  Future<void> record(GameStats game) {
    return _db.into(_db.gameStats).insert(game.toCompanion());
  }

  /// Games won under [categoryId]. Level-based mini-games use it as their
  /// progress, so they need no table of their own.
  Future<int> countWins(String categoryId) async {
    final row = await _db
        .customSelect(
          'SELECT COUNT(*) AS wins FROM game_stats '
          'WHERE category_id = ? AND won = 1',
          variables: [Variable.withString(categoryId)],
          readsFrom: {_db.gameStats},
        )
        .getSingle();
    return row.read<int>('wins');
  }

  /// Reads the snapshot now, then again after every write to the table.
  ///
  /// [sinceDay] bounds the per-day rows to the chart's window.
  Stream<StatsSnapshot> watchSnapshot({required String sinceDay}) {
    // The totals query reads the whole table, so drift re-runs it after any
    // write; it doubles as the trigger for the other three reads.
    return _totalsQuery().watchSingle().asyncMap(
      (row) => _snapshotWith(_bucketOf(row), sinceDay),
    );
  }

  Future<StatsSnapshot> readSnapshot({required String sinceDay}) async {
    final totals = _bucketOf(await _totalsQuery().getSingle());
    return _snapshotWith(totals, sinceDay);
  }

  Future<StatsSnapshot> _snapshotWith(
    StatsBucket totals,
    String sinceDay,
  ) async {
    final (record, daily, playedDays) = await (
      _readRecord(),
      _readDaily(sinceDay),
      _readPlayedDays(),
    ).wait;
    return StatsSnapshot(
      totals: totals,
      record: record,
      daily: daily,
      playedDays: playedDays,
    );
  }

  /// One page of the history, newest first.
  ///
  /// Pages by cursor ([beforeId] is the last id of the previous page), not
  /// by offset: `OFFSET 400` makes SQLite walk 400 rows to skip them, a
  /// cursor seeks straight to the next one.
  Future<List<GameStats>> recentGames({int limit = 20, int? beforeId}) async {
    final query = _db.select(_db.gameStats)
      ..orderBy([(g) => OrderingTerm.desc(g.id)])
      ..limit(limit);
    if (beforeId != null) query.where((g) => g.id.isSmallerThanValue(beforeId));
    final rows = await query.get();
    return [for (final row in rows) GameStats.fromRow(row)];
  }

  Selectable<QueryRow> _totalsQuery() {
    return _db.customSelect(
      'SELECT $_bucketColumns FROM game_stats',
      readsFrom: {_db.gameStats},
    );
  }

  static StatsBucket _bucketOf(QueryRow row) =>
      StatsBucket.fromColumns(row.data);

  Future<RecordGame?> _readRecord() async {
    final row = await _db
        .customSelect(
          'SELECT seconds_elapsed, pair_count FROM game_stats '
          'WHERE won = 1 AND pair_count > 0 '
          'ORDER BY CAST(seconds_elapsed AS REAL) / pair_count ASC, '
          'played_at ASC LIMIT 1',
          readsFrom: {_db.gameStats},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      seconds: row.read<int>('seconds_elapsed'),
      pairCount: row.read<int>('pair_count'),
    );
  }

  Future<List<DailyStats>> _readDaily(String sinceDay) async {
    final rows = await _db
        .customSelect(
          'SELECT played_day, $_bucketColumns FROM game_stats '
          'WHERE played_day >= ? GROUP BY played_day ORDER BY played_day',
          variables: [Variable.withString(sinceDay)],
          readsFrom: {_db.gameStats},
        )
        .get();
    return [
      for (final row in rows)
        (
          day: row.read<String>('played_day'),
          stats: StatsBucket.fromColumns(row.data),
        ),
    ];
  }

  Future<List<String>> _readPlayedDays() async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT played_day FROM game_stats ORDER BY played_day DESC',
          readsFrom: {_db.gameStats},
        )
        .get();
    return [for (final row in rows) row.read<String>('played_day')];
  }
}
