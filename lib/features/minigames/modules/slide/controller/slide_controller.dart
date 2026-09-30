import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/slide/model/slide_state.dart';
import 'package:memory_companion/features/minigames/modules/slide/slide_game_module.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs the sliding puzzle: shuffle the board for the level and take
/// slides until it is in order again. Like the crossword, a round only ends
/// solved: leaving the screen abandons it and records nothing.
class SlideController extends Notifier<SlideState> {
  static const _game = SlideGameModule();

  late DateTime _startedAt;

  @override
  SlideState build() {
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return SlideState.intro(level: ref.read(minigameLevelProvider(_game)));
  }

  void start({int? level}) {
    final difficulty = SlideDifficulty.forLevel(
      level ?? ref.read(minigameLevelProvider(_game)),
    );
    _startedAt = ref.read(statsClockProvider)();
    state = SlideState(
      phase: SlidePhase.playing,
      difficulty: difficulty,
      board: SlideBoard.shuffled(
        difficulty.size,
        difficulty.shuffleMoves,
        ref.read(minigameRandomProvider),
      ),
    );
  }

  void nextLevel() => start(level: state.level + 1);

  /// Slides the tile at [index] into the gap, if it touches it.
  void tap(int index) {
    if (state.phase != SlidePhase.playing) return;
    final next = state.board?.slide(index);
    if (next == null) return;
    state = state.copyWith(board: next, moves: state.moves + 1);
    if (next.solved) _finish();
  }

  void _finish() {
    state = state.copyWith(phase: SlidePhase.finished);
    final tiles = state.difficulty.size * state.difficulty.size - 1;
    final seconds = ref
        .read(statsClockProvider)()
        .difference(_startedAt)
        .inSeconds;
    unawaited(
      ref
          .read(minigameResultReporterProvider)
          .report(
            _game,
            MinigameResult(
              itemCount: tiles,
              itemsSolved: tiles,
              attempts: state.moves,
              secondsElapsed: max(0, seconds),
              won: true,
              score: state.score,
            ),
          ),
    );
  }
}

final slideControllerProvider =
    NotifierProvider.autoDispose<SlideController, SlideState>(
      SlideController.new,
    );
