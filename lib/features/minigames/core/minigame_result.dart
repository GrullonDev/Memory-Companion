/// The outcome of one finished round of any mini-game, in the vocabulary
/// the statistics panel already understands.
///
/// `game_stats` was designed around the memory board, but its columns are
/// generic once read as "units of work". Every game maps its round onto
/// them:
///
/// | field           | `game_stats` column | memory board     | e.g. number sequence  |
/// |-----------------|---------------------|------------------|-----------------------|
/// | [itemCount]     | `pair_count`        | pairs dealt      | digits to recall      |
/// | [itemsSolved]   | `matched_pairs`     | pairs found      | digits recalled       |
/// | [attempts]      | `moves`             | turns            | answers given         |
/// | [errors]        | `memory_errors`     | informed misses  | wrong answers         |
///
/// With that mapping, accuracy (`itemsSolved / attempts`), seconds per item,
/// streaks and weekly trends work for every game with no schema change.
///
/// Only record finished rounds (won or lost). An abandoned round says
/// nothing reliable about the player.
class MinigameResult {
  const MinigameResult({
    required this.itemCount,
    required this.itemsSolved,
    required this.attempts,
    required this.secondsElapsed,
    required this.won,
    required this.score,
    this.variantId,
    this.errors = 0,
    this.hintsUsed = 0,
    this.timeLimitSeconds = 0,
    this.timed = false,
  }) : assert(itemCount >= 0),
       assert(itemsSolved >= 0 && itemsSolved <= itemCount),
       assert(attempts >= 0),
       assert(errors >= 0),
       assert(secondsElapsed >= 0);

  /// Mode inside the game (the memory board's category, a sequence
  /// direction). Null for games with a single mode.
  final String? variantId;

  final int itemCount;
  final int itemsSolved;
  final int attempts;
  final int errors;
  final int hintsUsed;

  /// Real time played.
  final int secondsElapsed;
  final int timeLimitSeconds;
  final bool timed;

  final bool won;
  final int score;
}
