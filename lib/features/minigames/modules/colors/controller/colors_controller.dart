import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/colors/colors_game_module.dart';
import 'package:memory_companion/features/minigames/modules/colors/model/colors_state.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs a round of the colour game: [colorsItemsPerRound] words, each to be
/// answered with its ink colour before time runs out.
class ColorsController extends Notifier<ColorsState> {
  static const _game = ColorsGameModule();

  Timer? _timer;
  late DateTime _startedAt;

  @override
  ColorsState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return ColorsState.intro(level: ref.read(minigameLevelProvider(_game)));
  }

  void start({int? level}) {
    final difficulty = ColorsDifficulty.forLevel(
      level ?? ref.read(minigameLevelProvider(_game)),
    );
    final random = ref.read(minigameRandomProvider);
    _startedAt = ref.read(statsClockProvider)();
    state = ColorsState(
      phase: ColorsPhase.playing,
      difficulty: difficulty,
      items: [
        for (var i = 0; i < colorsItemsPerRound; i++)
          ColorsItem.deal(difficulty, random),
      ],
    );
    _schedule(difficulty.timeLimit, () => _answer(null));
  }

  void retry() => start(level: state.level);
  void nextLevel() => start(level: state.level + 1);

  void pick(InkColor color) {
    if (state.phase != ColorsPhase.playing) return;
    _answer(color);
  }

  void _answer(InkColor? color) {
    final item = state.current;
    if (item == null) return;
    final right = color == item.ink;
    state = state.copyWith(
      phase: ColorsPhase.feedback,
      correct: state.correct + (right ? 1 : 0),
      lastCorrect: right,
    );
    _schedule(colorsFeedbackDuration, () {
      final next = state.index + 1;
      if (next >= state.items.length) {
        _finish();
        return;
      }
      state = state.copyWith(phase: ColorsPhase.playing, index: next);
      _schedule(state.difficulty.timeLimit, () => _answer(null));
    });
  }

  void _finish() {
    state = state.copyWith(phase: ColorsPhase.finished);
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
              itemCount: state.items.length,
              itemsSolved: state.correct,
              attempts: state.items.length,
              errors: state.items.length - state.correct,
              secondsElapsed: max(0, seconds),
              timeLimitSeconds:
                  state.difficulty.timeLimitMs * state.items.length ~/ 1000,
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

final colorsControllerProvider =
    NotifierProvider.autoDispose<ColorsController, ColorsState>(
      ColorsController.new,
    );
