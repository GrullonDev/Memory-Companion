import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/game/model/match_rewards.dart';
import 'package:memory_companion/features/level_map/controller/level_controller.dart';

const _symbols = ['🍓', '🍌', '🍇', '🍉', '🍒', '🍍', '🥝', '🍑'];
const _totalSeconds = 90;

/// Owns the solo memory-board game logic (shuffling, flips, matching,
/// the countdown and the pause state). [BoardScreen] stays stateless and
/// only renders whatever [BoardState] this controller produces.
class BoardController extends Notifier<BoardState> {
  Timer? _timer;
  final List<int> _pendingFlips = [];

  @override
  BoardState build() {
    ref.onDispose(() => _timer?.cancel());
    _startTimer();
    return BoardState(
      matchId: const Uuid().v4(),
      cards: _shuffledCards(),
      totalSeconds: _totalSeconds,
      secondsRemaining: _totalSeconds,
    );
  }

  List<MemoryCard> _shuffledCards() {
    final symbols = [..._symbols, ..._symbols]..shuffle(Random());
    return [
      for (var i = 0; i < symbols.length; i++)
        MemoryCard(id: i, symbol: symbols[i]),
    ];
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isPaused || state.isCompleted) return;
      if (state.secondsRemaining <= 1) {
        _timer?.cancel();
        state = state.copyWith(secondsRemaining: 0, isCompleted: true);
        _onGameCompleted();
        return;
      }
      state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
    });
  }

  /// Fin de partida, por victoria o por agotarse el tiempo.
  ///
  /// Las recompensas se calculan **una sola vez** aquí, y ese mismo objeto
  /// alimenta el overlay de victoria y el guardado. Antes había tres cálculos
  /// distintos para el mismo evento: el jugador veía un número, cobraba otro
  /// y conservaba un tercero.
  Future<void> _onGameCompleted() async {
    final finished = state;
    final won = finished.cards.every((card) => card.isMatched);

    final rewards = calculateMatchRewards(
      score: finished.score,
      moves: finished.moves,
      timeLimit: finished.totalSeconds,
      secondsElapsed: finished.elapsedSeconds,
      won: won,
    );

    state = state.copyWith(
      coinsEarned: rewards.coins,
      xpEarned: rewards.xp,
      won: won,
    );

    // Escritura local: sin red de por medio, así que tampoco hace falta
    // tragarse el error con un `print`. Lo que falle aquí es un fallo real que
    // debe verse, no una desconexión que haya que tolerar.
    await ref.read(gameControllerProvider.notifier).completeSoloGame(
          matchId: finished.matchId,
          score: finished.score,
          moves: finished.moves,
          secondsElapsed: finished.elapsedSeconds,
          timeLimit: finished.totalSeconds,
          won: won,
          rewards: rewards,
          levelNumber: ref.read(selectedLevelProvider),
        );
  }

  void restart() {
    _pendingFlips.clear();
    // Reintentar es una partida nueva, con identidad nueva.
    state = BoardState(
      matchId: const Uuid().v4(),
      cards: _shuffledCards(),
      totalSeconds: _totalSeconds,
      secondsRemaining: _totalSeconds,
    );
    _startTimer();
  }

  void togglePause() {
    if (state.isCompleted) return;
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void flipCard(int index) {
    if (state.isPaused || state.isCompleted) return;
    final card = state.cards[index];
    if (card.isFaceUp || card.isMatched || _pendingFlips.length == 2) return;

    final updated = [...state.cards];
    updated[index] = card.copyWith(isFaceUp: true);
    _pendingFlips.add(index);
    state = state.copyWith(cards: updated);

    if (_pendingFlips.length == 2) {
      state = state.copyWith(moves: state.moves + 1);
      _resolvePendingFlips();
    }
  }

  Future<void> _resolvePendingFlips() async {
    final [firstIndex, secondIndex] = _pendingFlips;
    final first = state.cards[firstIndex];
    final second = state.cards[secondIndex];

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final updated = [...state.cards];
    final isMatch = first.symbol == second.symbol;
    updated[firstIndex] = first.copyWith(isFaceUp: isMatch, isMatched: isMatch);
    updated[secondIndex] = second.copyWith(
      isFaceUp: isMatch,
      isMatched: isMatch,
    );

    _pendingFlips.clear();
    final isCompleted = updated.every((c) => c.isMatched);
    state = state.copyWith(cards: updated, isCompleted: isCompleted);
    if (isCompleted) _timer?.cancel();
  }

  Future<void> useHint() async {
    if (state.isPaused || state.isCompleted || _pendingFlips.isNotEmpty) {
      return;
    }
    final target = state.cards.firstWhere(
      (c) => !c.isMatched,
      orElse: () => state.cards.first,
    );
    if (target.isMatched) return;

    final pairIndexes = [
      for (var i = 0; i < state.cards.length; i++)
        if (state.cards[i].symbol == target.symbol) i,
    ];

    var updated = [...state.cards];
    for (final i in pairIndexes) {
      updated[i] = updated[i].copyWith(isFaceUp: true);
    }
    state = state.copyWith(cards: updated);

    await Future<void>.delayed(const Duration(milliseconds: 800));

    updated = [...state.cards];
    for (final i in pairIndexes) {
      if (!updated[i].isMatched) {
        updated[i] = updated[i].copyWith(isFaceUp: false);
      }
    }
    state = state.copyWith(cards: updated);
  }
}

final boardControllerProvider = NotifierProvider<BoardController, BoardState>(
  BoardController.new,
);
