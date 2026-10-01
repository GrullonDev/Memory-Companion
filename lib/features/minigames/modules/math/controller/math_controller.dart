import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/math/math_game_module.dart';
import 'package:memory_companion/features/minigames/modules/math/model/math_state.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs a round of quick arithmetic: [mathProblemsPerRound] problems, each
/// against the clock. Running out of time counts as a wrong answer.
class MathController extends Notifier<MathState> {
  static const _game = MathGameModule();

  Timer? _timer;
  late DateTime _startedAt;

  @override
  MathState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return MathState.intro(level: ref.read(minigameLevelProvider(_game)));
  }

  void start({int? level}) {
    final difficulty = MathDifficulty.forLevel(
      level ?? ref.read(minigameLevelProvider(_game)),
    );
    final random = ref.read(minigameRandomProvider);
    _startedAt = ref.read(statsClockProvider)();
    state = MathState(
      phase: MathPhase.playing,
      difficulty: difficulty,
      problems: [
        for (var i = 0; i < mathProblemsPerRound; i++)
          MathProblem.deal(difficulty, random),
      ],
    );
    _schedule(difficulty.timeLimit, () => _answer(null));
  }

  void retry() => start(level: state.level);
  void nextLevel() => start(level: state.level + 1);

  void pick(int choice) {
    if (state.phase != MathPhase.playing) return;
    _answer(choice);
  }

  void _answer(int? choice) {
    final problem = state.current;
    if (problem == null) return;
    final right = choice == problem.answer;
    state = state.copyWith(
      phase: MathPhase.feedback,
      correct: state.correct + (right ? 1 : 0),
      lastCorrect: right,
      picked: () => choice,
    );
    _schedule(mathFeedbackDuration, () {
      final next = state.index + 1;
      if (next >= state.problems.length) {
        _finish();
        return;
      }
      state = state.copyWith(
        phase: MathPhase.playing,
        index: next,
        picked: () => null,
      );
      _schedule(state.difficulty.timeLimit, () => _answer(null));
    });
  }

  void _finish() {
    state = state.copyWith(
      phase: MathPhase.finished,
      index: state.problems.length,
    );
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
              itemCount: state.problems.length,
              itemsSolved: state.correct,
              attempts: state.problems.length,
              errors: state.problems.length - state.correct,
              secondsElapsed: max(0, seconds),
              timeLimitSeconds:
                  state.difficulty.timeLimitMs * state.problems.length ~/ 1000,
              timed: true,
              won: state.won,
              score: state.score,
            ),
          ),
    );
  }

  void _schedule(Duration delay, void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}

final mathControllerProvider =
    NotifierProvider.autoDispose<MathController, MathState>(MathController.new);
