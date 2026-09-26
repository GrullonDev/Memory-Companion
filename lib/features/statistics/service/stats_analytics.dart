import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/model/statistics_overview.dart';
import 'package:memory_companion/features/statistics/model/stats_bucket.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';

/// Turns a [StatsSnapshot] into what the statistics screen shows: streaks,
/// weekly evolution and the week-over-week trend.
///
/// Pure and synchronous. It never sees individual games — only per-day sums
/// the database already reduced — so its cost does not grow with history.
///
/// Weeks are rolling seven-day windows ending today, not calendar weeks: on
/// a Monday "this week" would otherwise be a single day and every trend
/// would read as noise.
class StatsAnalytics {
  const StatsAnalytics({this.weekCount = 8});

  /// How many weeks the evolution chart spans.
  final int weekCount;

  /// Fewer games than this on either side and a trend is not reported: two
  /// games are not a pattern, and telling an older player they got worse on
  /// the strength of one bad afternoon is exactly what this screen must not
  /// do.
  static const minGamesPerWindow = 2;

  /// A metric must move at least this much to count as a change.
  static const speedThreshold = 0.05; // 5 % faster or slower per pair.
  static const accuracyThreshold = 0.03; // 3 percentage points.
  static const errorsThreshold = 0.05; // errors per pair.

  /// First day, as a day key, the snapshot needs per-day rows from.
  String windowStartDay(DateTime today) {
    return dayKey(_addDays(today, -(weekCount * 7 - 1)));
  }

  StatisticsOverview analyze(StatsSnapshot snapshot, DateTime today) {
    final weeks = weeklyBuckets(snapshot.daily, today);
    final streaks = computeStreaks(snapshot.playedDays, today);
    return StatisticsOverview(
      totals: snapshot.totals,
      record: snapshot.record,
      currentStreak: streaks.current,
      bestStreak: streaks.best,
      playedToday:
          snapshot.playedDays.isNotEmpty &&
          snapshot.playedDays.first == dayKey(today),
      weeks: weeks,
      trend: compareWeeks(
        current: weeks.last.stats,
        previous: weeks[weeks.length - 2].stats,
      ),
    );
  }

  /// Folds per-day rows into [weekCount] seven-day windows, oldest first.
  /// Weeks without games are present and empty, so the chart keeps its gaps.
  List<WeeklyStats> weeklyBuckets(List<DailyStats> daily, DateTime today) {
    final firstDay = _addDays(today, -(weekCount * 7 - 1));
    final buckets = List.filled(weekCount, StatsBucket.empty);

    for (final (:day, :stats) in daily) {
      final offset = _dayNumber(parseDayKey(day)) - _dayNumber(firstDay);
      if (offset < 0 || offset >= weekCount * 7) continue;
      buckets[offset ~/ 7] += stats;
    }

    return [
      for (var i = 0; i < weekCount; i++)
        (start: _addDays(firstDay, i * 7), stats: buckets[i]),
    ];
  }

  /// Current and longest run of consecutive days played.
  ///
  /// [playedDays] is newest first. The current streak survives until the
  /// end of the day after the last game: at breakfast, yesterday's streak is
  /// still alive.
  ({int current, int best}) computeStreaks(
    List<String> playedDays,
    DateTime today,
  ) {
    if (playedDays.isEmpty) return (current: 0, best: 0);

    final days = [for (final d in playedDays) _dayNumber(parseDayKey(d))];
    final todayNumber = _dayNumber(today);

    var best = 1;
    var run = 1;
    int? current = todayNumber - days.first <= 1 ? null : 0;

    for (var i = 1; i < days.length; i++) {
      if (days[i - 1] - days[i] == 1) {
        run++;
      } else {
        current ??= run;
        run = 1;
      }
      if (run > best) best = run;
    }
    current ??= run;

    return (current: current, best: best);
  }

  StatsTrend compareWeeks({
    required StatsBucket current,
    required StatsBucket previous,
  }) {
    final enoughData =
        current.games >= minGamesPerWindow &&
        previous.games >= minGamesPerWindow;

    return StatsTrend(
      speed: _lowerIsBetter(
        current: current.secondsPerPair,
        previous: previous.secondsPerPair,
        enoughData: enoughData,
        threshold: speedThreshold,
        relativeThreshold: true,
      ),
      accuracy: _higherIsBetter(
        current: current.accuracy,
        previous: previous.accuracy,
        enoughData: enoughData,
      ),
      errors: _lowerIsBetter(
        current: current.errorsPerPair,
        previous: previous.errorsPerPair,
        enoughData: enoughData,
        threshold: errorsThreshold,
        relativeThreshold: false,
      ),
    );
  }

  /// Speed and errors: a drop is an improvement. [change] is reported
  /// relative to the previous week (0.2 = 20 % less) whenever that week is
  /// not zero; [relativeThreshold] picks whether the threshold applies to
  /// that ratio or to the raw difference.
  MetricTrend _lowerIsBetter({
    required double? current,
    required double? previous,
    required bool enoughData,
    required double threshold,
    required bool relativeThreshold,
  }) {
    if (!enoughData || current == null || previous == null) {
      return MetricTrend.notEnoughData(current: current, previous: previous);
    }
    final delta = previous - current;
    final relative = previous == 0 ? null : delta / previous;
    final measured = relativeThreshold ? (relative ?? 0) : delta;
    return MetricTrend(
      direction: _direction(measured, threshold),
      current: current,
      previous: previous,
      change: relative,
    );
  }

  MetricTrend _higherIsBetter({
    required double? current,
    required double? previous,
    required bool enoughData,
  }) {
    if (!enoughData || current == null || previous == null) {
      return MetricTrend.notEnoughData(current: current, previous: previous);
    }
    final delta = current - previous;
    return MetricTrend(
      direction: _direction(delta, accuracyThreshold),
      current: current,
      previous: previous,
      change: delta,
    );
  }

  static TrendDirection _direction(double improvement, double threshold) {
    if (improvement >= threshold) return TrendDirection.improving;
    if (improvement <= -threshold) return TrendDirection.declining;
    return TrendDirection.steady;
  }

  /// Calendar arithmetic through the constructor, not `Duration`: adding
  /// 24 h across a daylight-saving change lands on the wrong day.
  static DateTime _addDays(DateTime date, int days) {
    return DateTime(date.year, date.month, date.day + days);
  }

  /// Days since the epoch, ignoring time and time zone. Differences between
  /// two of these are exact day counts.
  static int _dayNumber(DateTime date) {
    return DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }
}
