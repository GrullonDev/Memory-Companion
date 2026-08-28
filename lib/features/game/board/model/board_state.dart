import 'package:memory_companion/features/game/board/model/memory_card.dart';

/// Immutable snapshot of a solo memory-board game.
class BoardState {
  const BoardState({
    required this.cards,
    required this.totalSeconds,
    required this.secondsRemaining,
    this.moves = 0,
    this.isPaused = false,
    this.isCompleted = false,
  });

  final List<MemoryCard> cards;
  final int moves;
  final int totalSeconds;
  final int secondsRemaining;
  final bool isPaused;
  final bool isCompleted;

  double get progress =>
      totalSeconds == 0 ? 0 : secondsRemaining / totalSeconds;

  BoardState copyWith({
    List<MemoryCard>? cards,
    int? moves,
    int? secondsRemaining,
    bool? isPaused,
    bool? isCompleted,
  }) {
    return BoardState(
      cards: cards ?? this.cards,
      totalSeconds: totalSeconds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      moves: moves ?? this.moves,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
