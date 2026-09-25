import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/crossword/controller/crossword_controller.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_game_module.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_levels.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_state.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';

void main() {
  // Algunas pruebas abren un segundo contenedor sobre la misma base.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  final provider = crosswordControllerProvider('es');

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Un contenedor sobre [db]: como volver a abrir el juego.
  Future<ProviderContainer> open() async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        minigameRandomProvider.overrideWithValue(Random(2)),
        statsClockProvider.overrideWithValue(() => DateTime(2026, 9, 24)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, _) {});
    await container.read(provider.future);
    return container;
  }

  CrosswordState stateOf(ProviderContainer c) => c.read(provider).requireValue;
  CrosswordController controllerOf(ProviderContainer c) =>
      c.read(provider.notifier);

  Future<int> wins() => StatsRepository(
    database: db,
  ).countWins(const CrosswordGameModule().statsKeyFor('es'));

  test('un jugador nuevo empieza en el nivel 1 con sus letras mezcladas', () async {
    final c = await open();
    final state = stateOf(c);
    expect(state.levelNumber, 1);
    expect(state.level, CrosswordLevels.forLanguage('es').first);
    expect([...state.wheel]..sort(), [...'SOL'.split('')]..sort());
    expect(state.found, isEmpty);
    expect(state.revealed, isEmpty);
  });

  test('distingue palabras encontradas, repetidas e inválidas', () async {
    final c = await open();

    controllerOf(c).submit('los');
    expect(stateOf(c).found, {'LOS'});
    expect(stateOf(c).feedback, CrosswordFeedback.found);
    expect(stateOf(c).revealed, containsAll(stateOf(c).layout.wordOf('LOS').cells));

    controllerOf(c).submit('LOS');
    expect(stateOf(c).feedback, CrosswordFeedback.repeated);
    expect(stateOf(c).attempts, 1, reason: 'repetir no cuenta como intento');

    controllerOf(c).submit('OSL');
    expect(stateOf(c).feedback, CrosswordFeedback.invalid);
    expect(stateOf(c).feedbackWord, 'OSL');
    expect(stateOf(c).errors, 1);

    // Menos de 3 letras: casi siempre es un roce, se ignora.
    controllerOf(c).submit('SO');
    expect(stateOf(c).feedbackWord, 'OSL');
    expect(stateOf(c).attempts, 2);
  });

  test('resolver registra la partida y la próxima vez abre el nivel 2', () async {
    final c = await open();
    controllerOf(c)
      ..submit('SOL')
      ..submit('LOS');
    expect(stateOf(c).solved, isTrue);
    await pumpEventQueue();
    expect(await wins(), 1);

    // Tras resolver, ya no se aceptan palabras.
    controllerOf(c).submit('XYZ');
    expect(stateOf(c).errors, 0);

    c.dispose();
    final reopened = await open();
    expect(stateOf(reopened).levelNumber, 2);
    expect(stateOf(reopened).level.letters, 'CASA');
  });

  test('"siguiente nivel" solo avanza con el crucigrama resuelto', () async {
    final c = await open();
    controllerOf(c).nextLevel();
    expect(stateOf(c).levelNumber, 1);

    controllerOf(c)
      ..submit('SOL')
      ..submit('LOS')
      ..nextLevel();
    expect(stateOf(c).levelNumber, 2);
    expect(stateOf(c).found, isEmpty);
    expect(stateOf(c).feedback, isNull);
  });

  test('las pistas revelan letras y completan palabras', () async {
    final c = await open();
    final cells = stateOf(c).layout.letters.length;

    controllerOf(c).hint();
    expect(stateOf(c).hintsUsed, 1);
    expect(stateOf(c).revealed, hasLength(1));

    while (!stateOf(c).solved) {
      controllerOf(c).hint();
    }
    expect(stateOf(c).hintsUsed, cells, reason: 'una letra nueva por pista');
    expect(stateOf(c).found, {'SOL', 'LOS'});
    // Cada palabra completada por pistas cuenta como intento, para que la
    // precisión de las estadísticas nunca pase del 100 %.
    expect(stateOf(c).attempts, 2);
    expect(stateOf(c).score, (6 - cells) * 10);
    await pumpEventQueue();
    expect(await wins(), 1);
  });

  test('mezclar cambia el orden, no las letras', () async {
    final c = await open();
    final before = stateOf(c).wheel;
    controllerOf(c).shuffle();
    expect([...stateOf(c).wheel]..sort(), [...before]..sort());
  });

  test('tras el último crucigrama se vuelve al primero', () async {
    final levels = CrosswordLevels.forLanguage('es');
    final reporter = MinigameResultReporter(
      repository: StatsRepository(database: db),
      clock: () => DateTime(2026, 9, 24),
    );
    for (var i = 0; i < levels.length; i++) {
      await reporter.report(
        const CrosswordGameModule(),
        const MinigameResult(
          variantId: 'es',
          itemCount: 2,
          itemsSolved: 2,
          attempts: 2,
          secondsElapsed: 30,
          won: true,
          score: 60,
        ),
      );
    }

    final c = await open();
    expect(stateOf(c).levelNumber, levels.length + 1);
    expect(stateOf(c).level, levels.first);
  });

  test('el progreso de cada idioma es independiente', () async {
    final c = await open();
    controllerOf(c)
      ..submit('SOL')
      ..submit('LOS');
    await pumpEventQueue();

    c.listen(crosswordControllerProvider('en'), (_, _) {});
    final english = await c.read(crosswordControllerProvider('en').future);
    expect(english.levelNumber, 1);
    expect(english.level.letters, 'CAT');
  });
}
