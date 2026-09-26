import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/digits/controller/digits_controller.dart';
import 'package:memory_companion/features/minigames/modules/digits/model/digits_state.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Guarda los resultados en memoria en lugar de en `game_stats`.
class _RecordingReporter implements MinigameResultReporter {
  final reports = <(BaseMinigame, MinigameResult)>[];

  @override
  Future<void> report(BaseMinigame game, MinigameResult result) async {
    reports.add((game, result));
  }
}

void main() {
  late _RecordingReporter reporter;

  /// Corre [body] con un reloj falso que también mueve `statsClockProvider`.
  void run(void Function(FakeAsync async, ProviderContainer container) body) {
    fakeAsync((async) {
      reporter = _RecordingReporter();
      final start = DateTime(2026, 9, 24, 10);
      final container = ProviderContainer(
        overrides: [
          minigameRandomProvider.overrideWithValue(Random(3)),
          minigameResultReporterProvider.overrideWithValue(reporter),
          statsClockProvider.overrideWithValue(
            () => start.add(async.elapsed),
          ),
        ],
      );
      // Mantiene vivo el controlador autoDispose durante la prueba.
      container.listen(digitsControllerProvider, (_, _) {});
      body(async, container);
      container.dispose();
    });
  }

  DigitsState stateOf(ProviderContainer c) => c.read(digitsControllerProvider);
  DigitsController controllerOf(ProviderContainer c) =>
      c.read(digitsControllerProvider.notifier);

  void type(ProviderContainer c, String digits) {
    for (final digit in digits.split('')) {
      controllerOf(c).typeDigit(int.parse(digit));
    }
  }

  /// Espera a que se oculte el número y responde bien o mal.
  void answer(FakeAsync async, ProviderContainer c, {required bool right}) {
    final state = stateOf(c);
    async.elapse(digitsShowDuration(state.span));
    expect(stateOf(c).phase, DigitsPhase.input);
    final expected = state.expectedAnswer;
    // Cambiar el primer dígito siempre da una respuesta equivocada.
    final wrong =
        '${(int.parse(expected[0]) + 1) % 10}${expected.substring(1)}';
    type(c, right ? expected : wrong);
    controllerOf(c).submit();
    async.elapse(digitsFeedbackDuration);
  }

  test('muestra el número, lo oculta y lo pide', () {
    run((async, c) {
      expect(stateOf(c).phase, DigitsPhase.intro);

      controllerOf(c).start(DigitsMode.forward);
      expect(stateOf(c).phase, DigitsPhase.showing);
      expect(stateOf(c).span, 3);
      expect(stateOf(c).sequence, hasLength(3));

      // Mientras se muestra no se puede escribir.
      controllerOf(c).typeDigit(1);
      expect(stateOf(c).input, isEmpty);

      async.elapse(digitsShowDuration(3));
      expect(stateOf(c).phase, DigitsPhase.input);
    });
  });

  test('no repite el mismo dígito seguido', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.forward);
      for (var i = 0; i < 8; i++) {
        answer(async, c, right: true);
      }
      final sequence = stateOf(c).sequence;
      for (var i = 1; i < sequence.length; i++) {
        expect(sequence[i], isNot(sequence[i - 1]), reason: sequence);
      }
    });
  });

  test('solo se comprueba con el número completo, y se puede borrar', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.forward);
      async.elapse(digitsShowDuration(3));

      type(c, '12');
      controllerOf(c).submit();
      expect(stateOf(c).phase, DigitsPhase.input);

      controllerOf(c).deleteDigit();
      expect(stateOf(c).input, '1');

      type(c, '2345');
      expect(stateOf(c).input, '123', reason: 'no pasa de la longitud');
    });
  });

  test('cada acierto suma un dígito y un fallo repite la longitud', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.forward);

      answer(async, c, right: true);
      expect(stateOf(c).span, 4);
      expect(stateOf(c).bestSpan, 3);

      answer(async, c, right: false);
      expect(stateOf(c).span, 4);
      expect(stateOf(c).misses, 1);

      answer(async, c, right: true);
      expect(stateOf(c).span, 5);
      expect(stateOf(c).misses, 0, reason: 'un acierto reinicia los fallos');
    });
  });

  test('al revés espera los dígitos del último al primero', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.reverse);
      final state = stateOf(c);
      expect(state.span, 2);

      async.elapse(digitsShowDuration(2));
      type(c, state.sequence);
      controllerOf(c).submit();
      expect(stateOf(c).lastCorrect, isFalse);

      async.elapse(digitsFeedbackDuration);
      final next = stateOf(c);
      async.elapse(digitsShowDuration(next.span));
      type(c, next.sequence.split('').reversed.join());
      controllerOf(c).submit();
      expect(stateOf(c).lastCorrect, isTrue);
    });
  });

  test('dos fallos seguidos terminan y registran la partida', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.forward);
      for (var i = 0; i < 4; i++) {
        answer(async, c, right: true);
      }
      answer(async, c, right: false);
      answer(async, c, right: false);

      expect(stateOf(c).phase, DigitsPhase.finished);
      expect(stateOf(c).bestSpan, 6);
      expect(stateOf(c).won, isFalse, reason: 'la meta son 7 dígitos');

      final [(game, result)] = reporter.reports;
      expect(game.id, 'digits');
      expect(game.statsKeyFor(result.variantId), 'digits');
      expect(result.itemCount, 6);
      expect(result.itemsSolved, 4);
      expect(result.attempts, 6);
      expect(result.errors, 2);
      expect(result.won, isFalse);
      expect(result.score, (3 + 4 + 5 + 6) * 10);
      expect(result.secondsElapsed, greaterThan(0));
    });
  });

  test('llegar a la meta gana, y al revés se guarda en su variante', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.reverse);
      // 2, 3, 4, 5 dígitos: la meta al revés.
      for (var i = 0; i < 4; i++) {
        answer(async, c, right: true);
      }
      answer(async, c, right: false);
      answer(async, c, right: false);

      expect(stateOf(c).won, isTrue);
      final [(game, result)] = reporter.reports;
      expect(game.statsKeyFor(result.variantId), 'digits:reverse');
      expect(result.won, isTrue);
    });
  });

  test('acertar el número más largo termina la partida', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.forward);
      while (stateOf(c).phase != DigitsPhase.finished) {
        answer(async, c, right: true);
      }
      expect(stateOf(c).bestSpan, digitsMaxSpan);
      expect(reporter.reports, hasLength(1));
    });
  });

  test('jugar otra vez empieza de cero', () {
    run((async, c) {
      controllerOf(c).start(DigitsMode.forward);
      answer(async, c, right: true);
      answer(async, c, right: false);
      answer(async, c, right: false);

      controllerOf(c).start(DigitsMode.forward);
      expect(stateOf(c).span, 3);
      expect(stateOf(c).trials, 0);
      expect(stateOf(c).bestSpan, 0);
    });
  });
}
