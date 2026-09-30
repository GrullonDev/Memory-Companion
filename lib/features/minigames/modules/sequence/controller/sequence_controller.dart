import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/sequence/model/sequence_state.dart';
import 'package:memory_companion/features/minigames/modules/sequence/sequence_game_module.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs the sequence game: light the pads one by one, then take the
/// player's taps. Every sequence repeated right adds one pad; two misses in
/// a row, or reaching the level's target length, end the round.
class SequenceController extends Notifier<SequenceState> {
  static const _game = SequenceGameModule();

  Timer? _timer;
  late DateTime _startedAt;

  Random get _random => ref.read(minigameRandomProvider);

  @override
  SequenceState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return SequenceState.intro(level: ref.read(minigameLevelProvider(_game)));
  }

  void start({int? level}) {
    final difficulty = SequenceDifficulty.forLevel(
      level ?? ref.read(minigameLevelProvider(_game)),
    );
    _startedAt = ref.read(statsClockProvider)();
    state = SequenceState(phase: SequencePhase.showing, difficulty: difficulty);
    _show(difficulty.startLength);
  }

  void retry() => start(level: state.level);
  void nextLevel() => start(level: state.level + 1);

  /// The player taps [pad].
  void tap(int pad) {
    if (state.phase != SequencePhase.input) return;
    if (state.sequence[state.entered] == pad) {
      final entered = state.entered + 1;
      state = state.copyWith(entered: entered, lit: () => pad);
      if (entered == state.length) _answer(correct: true);
    } else {
      state = state.copyWith(lit: () => pad);
      _answer(correct: false);
    }
  }

  void _answer({required bool correct}) {
    state = state.copyWith(
      phase: SequencePhase.feedback,
      trials: state.trials + 1,
      correct: state.correct + (correct ? 1 : 0),
      misses: correct ? 0 : state.misses + 1,
      bestLength: correct ? max(state.bestLength, state.length) : null,
      score: state.score + (correct ? state.length * 10 : 0),
      lastCorrect: correct,
    );
    _schedule(sequenceFeedbackDuration, () {
      if (state.misses >= sequenceMaxMisses || state.won) {
        _finish();
      } else {
        _show(state.lastCorrect ? state.length + 1 : state.length);
      }
    });
  }

  /// Deals a new sequence of [length] and plays it, pad by pad. Never the
  /// same pad twice in a row: two flashes of one pad blur into one.
  void _show(int length) {
    final pads = state.difficulty.pads;
    final sequence = <int>[];
    while (sequence.length < length) {
      final next = _random.nextInt(pads);
      if (sequence.isEmpty || sequence.last != next) sequence.add(next);
    }
    state = state.copyWith(
      phase: SequencePhase.showing,
      sequence: sequence,
      entered: 0,
      lit: () => null,
    );
    _play(0);
  }

  void _play(int step) {
    final difficulty = state.difficulty;
    _schedule(difficulty.gap, () {
      if (step >= state.length) {
        state = state.copyWith(phase: SequencePhase.input, lit: () => null);
        return;
      }
      state = state.copyWith(lit: () => state.sequence[step]);
      _schedule(difficulty.flash, () {
        state = state.copyWith(lit: () => null);
        _play(step + 1);
      });
    });
  }

  void _finish() {
    state = state.copyWith(phase: SequencePhase.finished, lit: () => null);
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
              itemCount: state.trials,
              itemsSolved: state.correct,
              attempts: state.trials,
              errors: state.trials - state.correct,
              secondsElapsed: max(0, seconds),
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

final sequenceControllerProvider =
    NotifierProvider.autoDispose<SequenceController, SequenceState>(
      SequenceController.new,
    );
