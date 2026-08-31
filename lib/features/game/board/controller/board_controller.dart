import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';

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

  /// Called when the game is completed (either won by finishing or lost by timeout)
  Future<void> _onGameCompleted() async {
    final currentState = state;
    final won = currentState.cards.every((c) => c.isMatched);

    // Calculate rewards
    final rewards = won
        ? _calculateRewards(
            score: currentState.score,
            moves: currentState.moves,
            secondsElapsed: currentState.elapsedSeconds,
            timeLimit: currentState.totalSeconds,
          )
        : {'coins': 0, 'xp': 10}; // Small XP for playing even if lost

    // Update state with rewards
    state = state.copyWith(
      coinsEarned: rewards['coins'] as int,
      xpEarned: rewards['xp'] as int,
      won: won,
    );

    // Save the game result to Firestore
    try {
      await ref.read(gameControllerProvider.notifier).completeSoloGame(
        score: currentState.score,
        moves: currentState.moves,
        secondsElapsed: currentState.elapsedSeconds,
        timeLimit: currentState.totalSeconds,
        won: won,
      );
    } catch (e) {
      // Silent fail - game is still playable even if Firestore is down
      print('Error saving game to Firestore: $e');
    }
  }

  /// Calculate rewards based on performance
  Map<String, int> _calculateRewards({
    required int score,
    required int moves,
    required int secondsElapsed,
    required int timeLimit,
  }) {
    // Base coins from score
    int coins = (score / 100).ceil();

    // Time bonus (up to 50% if finished in half the time)
    if (secondsElapsed < timeLimit ~/ 2) {
      coins += (coins * 0.5).ceil();
    }

    // Efficiency bonus (fewer moves = more coins)
    if (moves < 20) {
      coins += (coins * 0.3).ceil();
    }

    // XP calculation
    int xp = 50; // Base XP
    xp += (score / 100).ceil(); // Bonus from score
    if (secondsElapsed < timeLimit ~/ 2) {
      xp += 30; // Speed bonus
    }
    if (moves < 20) {
      xp += 20; // Efficiency bonus
    }

    return {'coins': coins.clamp(10, 1000), 'xp': xp.clamp(50, 500)};
  }

  void restart() {
    _pendingFlips.clear();
    state = BoardState(
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
