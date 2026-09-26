/// Summed metrics of a group of games: one day, one week, or all time.
///
/// Holds **sums**, never averages, so buckets add up exactly: a week is the
/// [+] of its days, and its accuracy is the ratio of the summed turns — a
/// 12-pair board weighs more than a 3-pair one, as it should.
class StatsBucket {
  const StatsBucket({
    this.games = 0,
    this.wins = 0,
    this.matchedPairs = 0,
    this.moves = 0,
    this.memoryErrors = 0,
    this.pairs = 0,
    this.wonSeconds = 0,
    this.wonPairs = 0,
  });

  static const empty = StatsBucket();

  final int games;
  final int wins;

  /// Pairs found and turns taken, across every game (won or lost).
  final int matchedPairs;
  final int moves;

  final int memoryErrors;

  /// Pairs on the board, summed across every game.
  final int pairs;

  /// Time and board size of **won** games only: a round lost to the clock
  /// always lasts exactly the limit, which would flatten any speed trend.
  final int wonSeconds;
  final int wonPairs;

  bool get isEmpty => games == 0;

  /// Share of turns that found a pair, 0–1. Null without turns.
  double? get accuracy => moves == 0 ? null : matchedPairs / moves;

  /// Seconds per pair in won games. Lower is faster. Null without wins.
  double? get secondsPerPair => wonPairs == 0 ? null : wonSeconds / wonPairs;

  /// Memory errors per pair on the board. Lower is better.
  double? get errorsPerPair => pairs == 0 ? null : memoryErrors / pairs;

  double? get winRate => games == 0 ? null : wins / games;

  StatsBucket operator +(StatsBucket other) {
    return StatsBucket(
      games: games + other.games,
      wins: wins + other.wins,
      matchedPairs: matchedPairs + other.matchedPairs,
      moves: moves + other.moves,
      memoryErrors: memoryErrors + other.memoryErrors,
      pairs: pairs + other.pairs,
      wonSeconds: wonSeconds + other.wonSeconds,
      wonPairs: wonPairs + other.wonPairs,
    );
  }

  /// Reads the columns every aggregate query in `StatsRepository` selects.
  factory StatsBucket.fromColumns(Map<String, Object?> data) {
    int read(String column) => (data[column] as int?) ?? 0;
    return StatsBucket(
      games: read('games'),
      wins: read('wins'),
      matchedPairs: read('matched_pairs'),
      moves: read('moves'),
      memoryErrors: read('memory_errors'),
      pairs: read('pairs'),
      wonSeconds: read('won_seconds'),
      wonPairs: read('won_pairs'),
    );
  }
}

/// One day's games, keyed by its local `'YYYY-MM-DD'`.
typedef DailyStats = ({String day, StatsBucket stats});

/// A seven-day window. [start] is local midnight of its first day.
typedef WeeklyStats = ({DateTime start, StatsBucket stats});

/// The fastest won game, measured per pair so a bigger board can still set
/// a record.
typedef RecordGame = ({int seconds, int pairCount});
