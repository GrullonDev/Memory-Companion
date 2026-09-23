import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/board/model/star_rating.dart';

/// Immutable snapshot of a solo memory-board game.
class BoardState {
  const BoardState({
    required this.cards,
    required this.totalSeconds,
    required this.secondsRemaining,
    this.previewSecondsRemaining = 0,
    this.isTimed = true,
    this.overtimeSeconds = 0,
    this.moves = 0,
    this.hintsUsed = 0,
    this.isPaused = false,
    this.isCompleted = false,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.won = false,
    this.level,
  });

  final List<MemoryCard> cards;
  final int moves;
  final int hintsUsed;
  final int totalSeconds;
  final int secondsRemaining;

  /// Seconds left in the opening look at the face-up board. The match clock
  /// does not run and cards cannot be flipped until it reaches zero.
  final int previewSecondsRemaining;

  /// Whether reaching zero ends the match. When false the countdown still
  /// runs — it feeds the score's time bonus exactly as in a timed match —
  /// but it is never shown and never ends anything.
  final bool isTimed;

  /// Seconds played after [secondsRemaining] reached zero in an untimed
  /// match, so the result screen reports the real time taken.
  final int overtimeSeconds;

  final bool isPaused;
  final bool isCompleted;
  final int coinsEarned;
  final int xpEarned;
  final bool won;

  /// The explicit level this board belongs to. Null on the daily board,
  /// which is the same for everyone and is not part of any progression.
  final int? level;

  /// Whether the finished board unlocked the next level.
  bool get canAdvanceLevel => isCompleted && won && level != null;

  bool get isPreviewing => previewSecondsRemaining > 0;

  double get progress =>
      totalSeconds == 0 ? 0 : secondsRemaining / totalSeconds;

  int get elapsedSeconds => totalSeconds - secondsRemaining + overtimeSeconds;

  int get pairCount => cards.length ~/ 2;

  int get matchedPairs => cards.where((c) => c.isMatched).length ~/ 2;

  /// Pair-completion bonus plus a time bonus, minus a small penalty per
  /// extra move — matches are worth more than speed, speed more than moves.
  int get score {
    final raw = pairCount * 500 + secondsRemaining * 10 - moves * 15;
    return raw < 0 ? 0 : raw;
  }

  /// 0–3 stars for the result screen. See [StarRating].
  int get stars => StarRating.of(
    won: won,
    moves: moves,
    pairCount: pairCount,
    elapsedSeconds: elapsedSeconds,
    timeLimitSeconds: totalSeconds,
  );

  BoardState copyWith({
    List<MemoryCard>? cards,
    int? moves,
    int? hintsUsed,
    int? secondsRemaining,
    int? previewSecondsRemaining,
    int? overtimeSeconds,
    bool? isPaused,
    bool? isCompleted,
    int? coinsEarned,
    int? xpEarned,
    bool? won,
  }) {
    return BoardState(
      cards: cards ?? this.cards,
      totalSeconds: totalSeconds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      previewSecondsRemaining:
          previewSecondsRemaining ?? this.previewSecondsRemaining,
      isTimed: isTimed,
      overtimeSeconds: overtimeSeconds ?? this.overtimeSeconds,
      moves: moves ?? this.moves,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      xpEarned: xpEarned ?? this.xpEarned,
      won: won ?? this.won,
      level: level,
    );
  }
}
