import 'package:memory_companion/features/game/board/category/game_category.dart';

/// Everything that makes one board easier or harder, resolved for a round.
class DifficultySettings {
  const DifficultySettings({
    required this.pairCount,
    required this.previewSeconds,
    required this.timeLimitSeconds,
    required this.mismatchRevealMs,
    required this.tier,
  });

  final int pairCount;

  /// How long every card is shown face up before play starts.
  final int previewSeconds;

  final int timeLimitSeconds;

  /// How long two non-matching cards stay visible before turning back.
  final int mismatchRevealMs;

  final ContentTier tier;

  /// Extra time on a missed pair, added only while the player keeps missing
  /// cards they had already seen. It gives them longer to re-read the cards
  /// without changing anything visible on the board.
  static const _reliefStepMs = 300;
  static const _maxReliefMs = 900;

  /// Mismatch reveal for this turn, given the current run of memory errors.
  /// The first two misses in a row get no extra time.
  Duration mismatchRevealFor(int consecutiveMemoryErrors) {
    final relief = ((consecutiveMemoryErrors - 2) * _reliefStepMs).clamp(
      0,
      _maxReliefMs,
    );
    return Duration(milliseconds: mismatchRevealMs + relief);
  }
}
