import 'package:memory_companion/features/game/board/model/memory_card.dart';

/// Immutable snapshot of a solo memory-board game.
class BoardState {
  const BoardState({
    required this.matchId,
    required this.cards,
    required this.totalSeconds,
    required this.secondsRemaining,
    this.moves = 0,
    this.isPaused = false,
    this.isCompleted = false,
    this.coinsEarned = 0,
    this.xpEarned = 0,
    this.won = false,
  });

  /// UUID generado **al empezar** la partida, no al guardarla.
  ///
  /// Que el id nazca con la partida es lo que hace idempotente el registro:
  /// reintentar el guardado sobrescribe la misma fila en vez de crear otra.
  final String matchId;

  final List<MemoryCard> cards;
  final int moves;
  final int totalSeconds;
  final int secondsRemaining;
  final bool isPaused;
  final bool isCompleted;
  final int coinsEarned;
  final int xpEarned;
  final bool won;

  double get progress =>
      totalSeconds == 0 ? 0 : secondsRemaining / totalSeconds;

  int get elapsedSeconds => totalSeconds - secondsRemaining;

  /// Pair-completion bonus plus a time bonus, minus a small penalty per
  /// extra move — matches are worth more than speed, speed more than moves.
  int get score {
    final pairs = cards.length ~/ 2;
    final raw = pairs * 500 + secondsRemaining * 10 - moves * 15;
    return raw < 0 ? 0 : raw;
  }

  BoardState copyWith({
    List<MemoryCard>? cards,
    int? moves,
    int? secondsRemaining,
    bool? isPaused,
    bool? isCompleted,
    int? coinsEarned,
    int? xpEarned,
    bool? won,
  }) {
    return BoardState(
      matchId: matchId,
      cards: cards ?? this.cards,
      totalSeconds: totalSeconds,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      moves: moves ?? this.moves,
      isPaused: isPaused ?? this.isPaused,
      isCompleted: isCompleted ?? this.isCompleted,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      xpEarned: xpEarned ?? this.xpEarned,
      won: won ?? this.won,
    );
  }
}
