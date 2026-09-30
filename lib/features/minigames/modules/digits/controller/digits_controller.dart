import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_game_module.dart';
import 'package:memory_companion/features/minigames/modules/digits/model/digits_state.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs a digit-span game: show a number, hide it, check the answer, and
/// grow the number by one digit after every correct answer.
///
/// One game is one stats row: every number answered is a trial, so
/// accuracy reads as "numbers recalled per number shown".
class DigitsController extends Notifier<DigitsState> {
  Timer? _timer;
  late DateTime _startedAt;

  Random get _random => ref.read(minigameRandomProvider);

  static const _game = DigitsGameModule();

  @override
  DigitsState build() {
    ref.onDispose(() => _timer?.cancel());
    // Keeps the ladder level loading while the intro is on screen.
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return const DigitsState.intro();
  }

  /// Starts a game at the player's ladder level, which sets how long the
  /// numbers start, how long they must get and how briefly they show.
  void start(DigitsMode mode) {
    _startedAt = ref.read(statsClockProvider)();
    final level = ref.read(minigameLevelProvider(_game));
    state = DigitsState(phase: DigitsPhase.intro, mode: mode, level: level);
    _show(state.startSpan);
  }

  void typeDigit(int digit) {
    assert(digit >= 0 && digit <= 9);
    if (state.phase != DigitsPhase.input || state.input.length >= state.span) {
      return;
    }
    state = state.copyWith(input: '${state.input}$digit');
  }

  void deleteDigit() {
    if (state.phase != DigitsPhase.input || state.input.isEmpty) return;
    state = state.copyWith(
      input: state.input.substring(0, state.input.length - 1),
    );
  }

  void submit() {
    if (!state.canSubmit) return;
    final correct = state.input == state.expectedAnswer;
    state = state.copyWith(
      phase: DigitsPhase.feedback,
      trials: state.trials + 1,
      correct: state.correct + (correct ? 1 : 0),
      misses: correct ? 0 : state.misses + 1,
      bestSpan: correct ? max(state.bestSpan, state.span) : null,
      score: state.score + (correct ? state.span * 10 : 0),
      lastCorrect: correct,
    );
    _schedule(digitsFeedbackDuration, _next);
  }

  void _next() {
    final outOfTries = state.misses >= digitsMaxMisses;
    final beatTheLongest = state.lastCorrect && state.span >= digitsMaxSpan;
    if (outOfTries || beatTheLongest) {
      _finish();
    } else {
      _show(state.lastCorrect ? state.span + 1 : state.span);
    }
  }

  void _show(int span) {
    state = state.copyWith(
      phase: DigitsPhase.showing,
      span: span,
      sequence: _deal(span),
      input: '',
    );
    _schedule(digitsShowDurationAt(span, level: state.level), () {
      state = state.copyWith(phase: DigitsPhase.input);
    });
  }

  /// Random digits, never the same one twice in a row: "77" is easier to
  /// hold than two different digits, and the span should not depend on luck.
  String _deal(int span) {
    final digits = <int>[];
    while (digits.length < span) {
      final next = _random.nextInt(10);
      if (digits.isEmpty || digits.last != next) digits.add(next);
    }
    return digits.join();
  }

  void _finish() {
    state = state.copyWith(phase: DigitsPhase.finished);
    final seconds = ref
        .read(statsClockProvider)()
        .difference(_startedAt)
        .inSeconds;
    final reporter = ref.read(minigameResultReporterProvider);
    unawaited(
      reporter.report(
        _game,
        MinigameResult(
          variantId: state.mode.variantId,
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

/// Discarded when the player leaves the game, which also cancels any
/// pending timer.
final digitsControllerProvider =
    NotifierProvider.autoDispose<DigitsController, DigitsState>(
      DigitsController.new,
    );
