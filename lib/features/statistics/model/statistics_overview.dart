import 'package:memory_companion/features/statistics/model/stats_bucket.dart';

/// Which way a metric moved between two windows, already oriented so that
/// [improving] is always good news — faster, more accurate, fewer errors.
enum TrendDirection { improving, steady, declining, notEnoughData }

/// One metric compared between the last seven days and the seven before.
class MetricTrend {
  const MetricTrend({
    required this.direction,
    this.current,
    this.previous,
    this.change,
  });

  const MetricTrend.notEnoughData({this.current, this.previous})
    : direction = TrendDirection.notEnoughData,
      change = null;

  final TrendDirection direction;
  final double? current;
  final double? previous;

  /// Size of the improvement, positive when better: a relative fraction for
  /// speed and errors (0.12 = 12 % faster), percentage points / 100 for
  /// accuracy. Null without data on both sides.
  final double? change;
}

/// This week against the last one.
class StatsTrend {
  const StatsTrend({
    required this.speed,
    required this.accuracy,
    required this.errors,
  });

  final MetricTrend speed;
  final MetricTrend accuracy;
  final MetricTrend errors;

  List<MetricTrend> get all => [speed, accuracy, errors];

  /// The one-line verdict the screen leads with. Deliberately generous: a
  /// single improving metric with nothing declining reads as progress.
  TrendDirection get overall {
    final directions = all
        .map((t) => t.direction)
        .where((d) => d != TrendDirection.notEnoughData)
        .toList();
    if (directions.isEmpty) return TrendDirection.notEnoughData;

    final up = directions.where((d) => d == TrendDirection.improving).length;
    final down = directions.where((d) => d == TrendDirection.declining).length;
    if (up > down) return TrendDirection.improving;
    if (down > up) return TrendDirection.declining;
    return TrendDirection.steady;
  }
}

/// Everything the statistics screen shows except the game-by-game history,
/// which is paged separately.
class StatisticsOverview {
  const StatisticsOverview({
    required this.totals,
    required this.record,
    required this.currentStreak,
    required this.bestStreak,
    required this.playedToday,
    required this.weeks,
    required this.trend,
  });

  final StatsBucket totals;
  final RecordGame? record;

  /// Consecutive days played, ending today — or yesterday, so a streak is
  /// not shown as broken in the morning before today's game.
  final int currentStreak;
  final int bestStreak;
  final bool playedToday;

  /// Oldest first; the last entry is the current seven days.
  final List<WeeklyStats> weeks;
  final StatsTrend trend;

  bool get isEmpty => totals.isEmpty;
}
