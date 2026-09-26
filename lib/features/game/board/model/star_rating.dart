/// 0–3 stars for a finished solo board, from how many moves it took and how
/// long.
///
/// Deliberately generous — the same rule has to motivate a child racing the
/// clock and an older player who switched the countdown off:
///
///  * **Winning always earns at least one star.** A finished board is never
///    a failure; only running out of time gives zero.
///  * **Moves and time are worth the same.** Each earns up to two points,
///    so a slow but careful game can still reach three stars, and so can a
///    fast one with a few extra flips.
///  * **Relative to the board.** Moves are measured per pair and time
///    against the board's own limit, so a bigger adaptive board is not
///    rated more harshly than a small one.
abstract final class StarRating {
  static const maxStars = 3;

  /// Moves per pair at or under which the moves earn full points. A player
  /// with perfect recall still has to turn over unseen cards, so even ideal
  /// play needs ~1.6 moves per pair on average.
  static const efficientMovesPerPair = 2.0;

  /// Moves per pair at or under which the moves earn one point.
  static const fairMovesPerPair = 3.0;

  /// Share of the time limit at or under which the time earns full points.
  static const fastTimeShare = 0.5;

  /// Share of the time limit at or under which the time earns one point.
  /// Over 1.0 is only reachable in an untimed match.
  static const fairTimeShare = 1.0;

  static int of({
    required bool won,
    required int moves,
    required int pairCount,
    required int elapsedSeconds,
    required int timeLimitSeconds,
  }) {
    if (!won) return 0;

    final points =
        _points(
          value: pairCount == 0 ? 0 : moves / pairCount,
          full: efficientMovesPerPair,
          fair: fairMovesPerPair,
        ) +
        _points(
          value: timeLimitSeconds == 0 ? 0 : elapsedSeconds / timeLimitSeconds,
          full: fastTimeShare,
          fair: fairTimeShare,
        );

    // 0–1 points → 1 star, 2 → 2 stars, 3–4 → 3 stars.
    return switch (points) {
      <= 1 => 1,
      2 => 2,
      _ => maxStars,
    };
  }

  /// 2 at or under [full], 1 at or under [fair], else 0. Lower is better.
  static int _points({
    required double value,
    required double full,
    required double fair,
  }) {
    if (value <= full) return 2;
    if (value <= fair) return 1;
    return 0;
  }
}
