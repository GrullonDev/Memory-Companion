import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:memory_companion/features/daily_challenge/model/daily_challenge.dart';
import 'package:memory_companion/features/game/board/category/board_factory.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/model/shared_board.dart';
import 'package:memory_companion/features/game/board/rules/round_tracker.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/game/model/match_rewards.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/level_map/controller/level_map_controller.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/memory/memory_game_module.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';

/// Which board to deal: the game mode and the language its words are in.
typedef BoardSetup = ({GameCategory category, String languageCode});

/// Which daily board to deal: the day's challenge and the card language.
typedef DailyBoardSetup = ({DailyChallenge challenge, String languageCode});

/// Any other [SharedBoard] (a versus duel) and the card language.
typedef SharedBoardSetup = ({SharedBoard board, String languageCode});

/// Source of shuffling. Overridden in tests to deal a known board.
final boardRandomProvider = Provider<Random>((ref) => Random());

/// How long a found pair stays up before settling as matched.
const _matchRevealDelay = Duration(milliseconds: 600);

/// Owns the solo memory-board game logic (dealing, the opening preview,
/// flips, matching, the countdown and the pause state). [BoardScreen] stays
/// stateless and only renders whatever [BoardState] this controller produces.
///
/// Mode-agnostic by design: what the cards show comes from the
/// [GameCategory], whether two cards match from its `matchRule`, and board
/// size and timings from [AdaptiveDifficultyController]. The player's
/// [DisplayPreferences] can switch the countdown off and lengthen the
/// mismatch reveal; they are read once per round, so changing a setting
/// from the pause menu applies from the next round on.
///
/// Each adaptive board is one explicit level (see `SkillState.level`):
/// winning moves the category's level on as part of recording the round,
/// so [nextLevel] only has to deal what the engine now says. Losing keeps
/// the level, and [restart] replays it.
///
/// A [shared] board (the daily challenge or a versus duel) overrides three
/// of those: it is dealt from a fixed seed, with fixed settings, and never on
/// a countdown — so every player gets the same board and the result is a
/// time, not a win or loss.
class BoardController extends Notifier<BoardState> {
  BoardController(this.setup) : shared = null;

  BoardController.daily(DailyBoardSetup dailySetup)
    : shared = dailySetup.challenge,
      setup = (
        category: dailySetup.challenge.category,
        languageCode: dailySetup.languageCode,
      );

  BoardController.shared(SharedBoardSetup sharedSetup)
    : shared = sharedSetup.board,
      setup = (
        category: sharedSetup.board.category,
        languageCode: sharedSetup.languageCode,
      );

  final BoardSetup setup;
  final SharedBoard? shared;

  Timer? _timer;
  final List<int> _pendingFlips = [];
  late DifficultySettings _settings;
  late RoundTracker _tracker;
  late DisplayPreferences _preferences;

  /// Bumped on every new round, so a flip or hint still waiting on a delay
  /// from the previous round does not write into the new board.
  int _round = 0;

  GameCategory get _category => setup.category;

  @override
  BoardState build() {
    ref.onDispose(() => _timer?.cancel());
    return _newRound();
  }

  BoardState _newRound() {
    _round++;
    _pendingFlips.clear();
    final difficulty = ref.read(adaptiveDifficultyProvider.notifier);
    _settings = shared?.settings ?? difficulty.settingsFor(_category);
    _tracker = RoundTracker(_category.matchRule);
    _preferences = ref.read(displayPreferencesProvider);

    final cards = BoardFactory.deal(
      category: _category,
      settings: _settings,
      languageCode: setup.languageCode,
      random: shared?.random ?? ref.read(boardRandomProvider),
    );

    _startTimer();
    return BoardState(
      // Una partida nueva, con identidad nueva: reintentar no reusa el id.
      matchId: const Uuid().v4(),
      // Dealt face up for the preview; [_tick] turns them over.
      cards: [for (final c in cards) c.copyWith(isFaceUp: true)],
      totalSeconds: _settings.timeLimitSeconds,
      secondsRemaining: _settings.timeLimitSeconds,
      previewSecondsRemaining: _settings.previewSeconds,
      isTimed: shared == null && _preferences.timedMatches,
      level: shared == null ? difficulty.skillFor(_category).level : null,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.isPaused || state.isCompleted) return;

    if (state.isPreviewing) {
      final left = state.previewSecondsRemaining - 1;
      state = state.copyWith(
        previewSecondsRemaining: left,
        cards: left == 0
            ? [for (final c in state.cards) c.copyWith(isFaceUp: false)]
            : null,
      );
      return;
    }

    if (!state.isTimed) {
      state = state.secondsRemaining > 0
          ? state.copyWith(secondsRemaining: state.secondsRemaining - 1)
          : state.copyWith(overtimeSeconds: state.overtimeSeconds + 1);
      return;
    }

    if (state.secondsRemaining <= 1) {
      _timer?.cancel();
      state = state.copyWith(secondsRemaining: 0, isCompleted: true);
      _onGameCompleted();
      return;
    }
    state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
  }

  /// Fin de partida, por victoria o por agotarse el tiempo.
  ///
  /// Las recompensas se calculan **una sola vez** aquí, y ese mismo objeto
  /// alimenta el overlay de victoria y el guardado. Antes había tres cálculos
  /// distintos para el mismo evento: el jugador veía un número, cobraba otro
  /// y conservaba un tercero.
  Future<void> _onGameCompleted() async {
    final finished = state;
    final won = finished.cards.every((c) => c.isMatched);

    // Before anything async: the next round, even one started straight from
    // the victory overlay, must already be dealt with the adjusted settings.
    // A shared board is not the player's own difficulty, so it says nothing
    // about how the next adaptive board should be.
    if (shared == null) {
      ref
          .read(adaptiveDifficultyProvider.notifier)
          .recordRound(
            _category,
            RoundPerformance(
              pairCount: finished.pairCount,
              matchedPairs: finished.matchedPairs,
              memoryErrors: _tracker.memoryErrors,
              hintsUsed: finished.hintsUsed,
              secondsRemaining: finished.secondsRemaining,
              timeLimitSeconds: finished.totalSeconds,
              won: won,
            ),
          );
    }

    final rewards = calculateMatchRewards(
      score: finished.score,
      moves: finished.moves,
      timeLimit: finished.totalSeconds,
      secondsElapsed: finished.elapsedSeconds,
      won: won,
    );

    // Winning a board completes its level; on a reward step the overlay
    // announces the prize, and `LadderService` pays it (see
    // `AdaptiveDifficultyController.recordRound`).
    final completedLevel = won ? finished.level : null;
    state = state.copyWith(
      coinsEarned: rewards.coins,
      xpEarned: rewards.xp,
      won: won,
      levelReward: completedLevel == null
          ? null
          : LevelRewards.forCompletedLevel(completedLevel),
    );

    // Local statistics, on their own: they need no account and no network.
    // Started, not awaited, before the next `ref.read`: if the player leaves
    // the board meanwhile, this provider is disposed and `ref` stops working.
    final statsSaved = _recordStats(finished, won: won);

    // Escritura local: sin red de por medio, así que tampoco hace falta
    // tragarse el error con un `print`. Lo que falle aquí es un fallo real que
    // debe verse, no una desconexión que haya que tolerar.
    //
    // Only the level map's category has levels on the map; `finished.level`
    // is the level just played, read before [recordRound] raised it.
    await ref
        .read(gameControllerProvider.notifier)
        .completeSoloGame(
          matchId: finished.matchId,
          score: finished.score,
          moves: finished.moves,
          secondsElapsed: finished.elapsedSeconds,
          timeLimit: finished.totalSeconds,
          won: won,
          rewards: rewards,
          levelNumber: _category.id == levelMapCategory.id
              ? finished.level
              : null,
        );
    await statsSaved;
  }

  /// Reports through the platform's shared door to `game_stats`, like any
  /// other mini-game. The reporter never throws.
  Future<void> _recordStats(BoardState finished, {required bool won}) {
    return ref
        .read(minigameResultReporterProvider)
        .report(
          const MemoryGameModule(),
          MinigameResult(
            variantId: _category.id,
            itemCount: finished.pairCount,
            itemsSolved: finished.matchedPairs,
            attempts: finished.moves,
            errors: _tracker.memoryErrors,
            hintsUsed: finished.hintsUsed,
            secondsElapsed: finished.elapsedSeconds,
            timeLimitSeconds: finished.totalSeconds,
            timed: finished.isTimed,
            won: won,
            score: finished.score,
          ),
        );
  }

  /// Replays the board from the start. After a loss that is the same level
  /// again; the adaptive board may still be a little gentler.
  void restart() {
    state = _newRound();
  }

  /// Deals the next board after a win. Difficulty is continuous (see
  /// [AdaptiveDifficulty]), so "next level" is simply the next round: the
  /// round just won was already recorded, and the new board is dealt with
  /// the settings it earned — usually a little harder.
  void nextLevel() => restart();

  void togglePause() {
    if (state.isCompleted) return;
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void flipCard(int index) {
    if (state.isPaused || state.isCompleted || state.isPreviewing) return;
    final card = state.cards[index];
    if (card.isFaceUp || card.isMatched || _pendingFlips.length == 2) return;

    final updated = [...state.cards];
    updated[index] = card.copyWith(
      isFaceUp: true,
      flipCount: card.flipCount + 1,
    );
    _pendingFlips.add(index);
    state = state.copyWith(cards: updated);

    if (_pendingFlips.length == 2) {
      state = state.copyWith(moves: state.moves + 1);
      _resolvePendingFlips();
    }
  }

  Future<void> _resolvePendingFlips() async {
    final round = _round;
    final [firstIndex, secondIndex] = _pendingFlips;
    final first = state.cards[firstIndex];
    final second = state.cards[secondIndex];

    final isMatch = _tracker.recordTurn(first, second, state.cards);
    await Future<void>.delayed(isMatch ? _matchRevealDelay : _mismatchReveal());
    if (!ref.mounted || round != _round || state.isCompleted) return;

    final updated = [...state.cards];
    updated[firstIndex] = first.copyWith(isFaceUp: isMatch, isMatched: isMatch);
    updated[secondIndex] = second.copyWith(
      isFaceUp: isMatch,
      isMatched: isMatch,
    );

    _pendingFlips.clear();
    final isCompleted = updated.every((c) => c.isMatched);
    state = state.copyWith(cards: updated, isCompleted: isCompleted);
    if (isCompleted) {
      _timer?.cancel();
      _onGameCompleted();
    }
  }

  /// The difficulty's reveal, never shorter than the player's floor.
  Duration _mismatchReveal() {
    final adaptive = _settings.mismatchRevealFor(
      _tracker.consecutiveMemoryErrors,
    );
    final floor = _preferences.mismatchRevealFloor;
    return adaptive > floor ? adaptive : floor;
  }

  Future<void> useHint() async {
    if (state.isPaused ||
        state.isCompleted ||
        state.isPreviewing ||
        _pendingFlips.isNotEmpty) {
      return;
    }
    final round = _round;
    final targetIndex = state.cards.indexWhere((c) => !c.isMatched);
    if (targetIndex == -1) return;
    final target = state.cards[targetIndex];

    final rule = _category.matchRule;
    final pairIndexes = [
      targetIndex,
      for (var i = 0; i < state.cards.length; i++)
        if (rule.isMatch(target, state.cards[i])) i,
    ];
    _tracker.markSeen(pairIndexes.map((i) => state.cards[i].id));

    var updated = [...state.cards];
    for (final i in pairIndexes) {
      updated[i] = updated[i].copyWith(isFaceUp: true);
    }
    state = state.copyWith(cards: updated, hintsUsed: state.hintsUsed + 1);

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!ref.mounted || round != _round) return;

    updated = [...state.cards];
    for (final i in pairIndexes) {
      if (!updated[i].isMatched) {
        updated[i] = updated[i].copyWith(isFaceUp: false);
      }
    }
    state = state.copyWith(cards: updated);
  }
}

/// One board per setup, discarded when the player leaves it so the next
/// visit deals a fresh round with the latest difficulty.
final boardControllerProvider = NotifierProvider.autoDispose
    .family<BoardController, BoardState, BoardSetup>(BoardController.new);

/// The day's shared board. Same lifecycle as [boardControllerProvider].
final dailyBoardControllerProvider = NotifierProvider.autoDispose
    .family<BoardController, BoardState, DailyBoardSetup>(
      BoardController.daily,
    );

/// A duel's shared board. Same lifecycle as [boardControllerProvider].
final sharedBoardControllerProvider = NotifierProvider.autoDispose
    .family<BoardController, BoardState, SharedBoardSetup>(
      BoardController.shared,
    );
