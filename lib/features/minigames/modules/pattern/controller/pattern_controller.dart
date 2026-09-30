import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/pattern/model/pattern_state.dart';
import 'package:memory_companion/features/minigames/modules/pattern/pattern_game_module.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs a pattern round: light some cells, hide them, and let the player
/// tap where they were. One board is one round and one stats row.
class PatternController extends Notifier<PatternState> {
  static const _game = PatternGameModule();

  Timer? _timer;
  late DateTime _startedAt;

  @override
  PatternState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return PatternState.intro(level: ref.read(minigameLevelProvider(_game)));
  }

  void start({int? level}) {
    final difficulty = PatternDifficulty.forLevel(
      level ?? ref.read(minigameLevelProvider(_game)),
    );
    final cells = List<int>.generate(
      difficulty.gridSize * difficulty.gridSize,
      (i) => i,
    )..shuffle(ref.read(minigameRandomProvider));
    _startedAt = ref.read(statsClockProvider)();
    state = PatternState(
      phase: PatternPhase.showing,
      difficulty: difficulty,
      lit: cells.take(difficulty.litCount).toSet(),
    );
    _timer?.cancel();
    _timer = Timer(difficulty.showDuration, hide);
  }

  void retry() => start(level: state.level);
  void nextLevel() => start(level: state.level + 1);

  /// Hides the pattern early — the player is ready.
  void hide() {
    if (state.phase != PatternPhase.showing) return;
    _timer?.cancel();
    state = state.copyWith(phase: PatternPhase.input);
  }

  void tap(int cell) {
    if (state.phase != PatternPhase.input) return;
    if (state.found.contains(cell) || state.wrong.contains(cell)) return;
    final next = state.lit.contains(cell)
        ? state.copyWith(found: {...state.found, cell})
        : state.copyWith(wrong: {...state.wrong, cell});
    state = next;
    if (next.won || next.lost) _finish();
  }

  void _finish() {
    state = state.copyWith(phase: PatternPhase.finished);
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
              itemCount: state.lit.length,
              itemsSolved: state.found.length,
              attempts: state.found.length + state.errors,
              errors: state.errors,
              secondsElapsed: max(0, seconds),
              won: state.won,
              score: state.score,
            ),
          ),
    );
  }
}

final patternControllerProvider =
    NotifierProvider.autoDispose<PatternController, PatternState>(
      PatternController.new,
    );
