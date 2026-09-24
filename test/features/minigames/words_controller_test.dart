import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/words/controller/words_controller.dart';
import 'package:memory_companion/features/minigames/modules/words/model/word_bank.dart';
import 'package:memory_companion/features/minigames/modules/words/model/words_state.dart';
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
  final provider = wordsControllerProvider('es');

  void run(void Function(FakeAsync async, ProviderContainer container) body) {
    fakeAsync((async) {
      reporter = _RecordingReporter();
      final start = DateTime(2026, 9, 24, 10);
      final container = ProviderContainer(
        overrides: [
          minigameRandomProvider.overrideWithValue(Random(5)),
          minigameResultReporterProvider.overrideWithValue(reporter),
          statsClockProvider.overrideWithValue(
            () => start.add(async.elapsed),
          ),
        ],
      );
      container.listen(provider, (_, _) {});
      body(async, container);
      container.dispose();
    });
  }

  WordsState stateOf(ProviderContainer c) => c.read(provider);
  WordsController controllerOf(ProviderContainer c) =>
      c.read(provider.notifier);

  /// Responde todas las palabras, acertando solo las [right] primeras.
  void answerAll(ProviderContainer c, {int? right}) {
    var i = 0;
    while (stateOf(c).currentProbe != null) {
      final probe = stateOf(c).currentProbe!;
      final truth = stateOf(c).studied.contains(probe);
      final correct = right == null || i < right;
      controllerOf(c).answer(wasOnList: correct ? truth : !truth);
      i++;
    }
  }

  test('cada banco tiene palabras distintas para el nivel más largo', () {
    for (final language in WordBank.languages) {
      final words = WordBank.forLanguage(language);
      expect(words.toSet(), hasLength(words.length), reason: language);
      expect(
        words.length,
        greaterThanOrEqualTo(2 * wordsMaxListSize),
        reason: language,
      );
    }
    expect(WordBank.forLanguage('fr'), WordBank.forLanguage('es'));
  });

  test('reparte la lista y la mitad de preguntas son palabras nuevas', () {
    run((async, c) {
      controllerOf(c).start();
      final state = stateOf(c);
      expect(state.phase, WordsPhase.study);
      expect(state.studied, hasLength(wordsStartListSize));
      expect(state.probes, hasLength(2 * wordsStartListSize));
      expect(state.probes.toSet(), hasLength(state.probes.length));
      expect(state.probes.where(state.studied.contains), hasLength(4));
      // Durante el estudio no se responde.
      expect(state.currentProbe, isNull);
    });
  });

  test('el estudio termina solo o al tocar "listo"', () {
    run((async, c) {
      controllerOf(c).start();
      async.elapse(wordsStudyDuration(wordsStartListSize));
      expect(stateOf(c).phase, WordsPhase.test);

      controllerOf(c).start();
      controllerOf(c).finishStudy();
      expect(stateOf(c).phase, WordsPhase.test);
      // El temporizador anterior no vuelve a cambiar de fase.
      async.elapse(wordsStudyDuration(wordsStartListSize));
      expect(stateOf(c).phase, WordsPhase.test);
    });
  });

  test('responder bien todo gana, registra la ronda y sube de nivel', () {
    run((async, c) {
      controllerOf(c).start();
      controllerOf(c).finishStudy();
      answerAll(c);

      expect(stateOf(c).phase, WordsPhase.finished);
      expect(stateOf(c).correct, 8);
      expect(stateOf(c).won, isTrue);

      final [(game, result)] = reporter.reports;
      expect(game.id, 'words');
      expect(game.statsKeyFor(result.variantId), 'words');
      expect(result.itemCount, 8);
      expect(result.itemsSolved, 8);
      expect(result.errors, 0);
      expect(result.score, 80);

      controllerOf(c).nextLevel();
      expect(stateOf(c).listSize, wordsStartListSize + wordsListSizeStep);
      expect(stateOf(c).studied, hasLength(6));
    });
  });

  test('responder siempre "sí" no pasa del 50 %', () {
    run((async, c) {
      controllerOf(c).start();
      controllerOf(c).finishStudy();
      while (stateOf(c).currentProbe != null) {
        controllerOf(c).answer(wasOnList: true);
      }
      expect(stateOf(c).correct, 4);
      expect(stateOf(c).errors, 4);
      expect(stateOf(c).won, isFalse);
    });
  });

  test('por debajo del 80 % se repite el mismo nivel', () {
    run((async, c) {
      controllerOf(c).start();
      controllerOf(c).finishStudy();
      answerAll(c, right: 6); // 6 de 8 = 75 %
      expect(stateOf(c).won, isFalse);
      expect(reporter.reports.single.$2.won, isFalse);

      controllerOf(c).start();
      expect(stateOf(c).listSize, wordsStartListSize);
      expect(stateOf(c).answered, 0);
    });
  });

  test('el nivel no pasa del máximo', () {
    run((async, c) {
      controllerOf(c).start(listSize: wordsMaxListSize);
      controllerOf(c).finishStudy();
      answerAll(c);
      controllerOf(c).nextLevel();
      expect(stateOf(c).listSize, wordsMaxListSize);
    });
  });
}
