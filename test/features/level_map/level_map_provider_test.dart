import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/game/board/difficulty/skill_repository.dart';
import 'package:memory_companion/features/level_map/controller/level_map_controller.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('LevelNode.pathAround', () {
    Map<int, LevelStatus> statuses(int current) => {
      for (final node in LevelNode.pathAround(current))
        node.number: node.status,
    };

    test('un jugador nuevo: el 1 es el actual y el resto está bloqueado', () {
      expect(statuses(1), {
        1: LevelStatus.current,
        2: LevelStatus.locked,
        3: LevelStatus.locked,
        4: LevelStatus.locked,
        5: LevelStatus.locked,
        6: LevelStatus.locked,
      });
    });

    test('los niveles superados salen completados, no bloqueados', () {
      expect(statuses(5), {
        3: LevelStatus.completed,
        4: LevelStatus.completed,
        5: LevelStatus.current,
        6: LevelStatus.locked,
        7: LevelStatus.locked,
        8: LevelStatus.locked,
      });
    });

    test('el camino tiene siempre el mismo largo y un único actual', () {
      for (final current in [1, 2, 3, 10, 250]) {
        final path = LevelNode.pathAround(current);
        expect(path, hasLength(6));
        expect(
          path.where((n) => n.status == LevelStatus.current).single.number,
          current,
        );
      }
    });

    test('un nivel inválido se trata como el 1', () {
      expect(LevelNode.pathAround(0), LevelNode.pathAround(1));
    });
  });

  group('levelMapProvider', () {
    late AppDatabase db;
    late ProviderContainer container;

    const win = RoundPerformance(
      pairCount: 6,
      matchedPairs: 6,
      memoryErrors: 0,
      hintsUsed: 0,
      secondsRemaining: 60,
      timeLimitSeconds: 120,
      won: true,
    );

    ProviderContainer buildContainer() => ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );

    int currentLevel() => container
        .read(levelMapProvider)
        .singleWhere((n) => n.status == LevelStatus.current)
        .number;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = buildContainer();
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('ganar un tablero redibuja el mapa al instante', () async {
      final updates = <List<LevelNode>>[];
      container.listen(levelMapProvider, (_, next) => updates.add(next));
      await pumpEventQueue(); // Restauración inicial (base vacía).
      expect(currentLevel(), 1);

      container
          .read(adaptiveDifficultyProvider.notifier)
          .recordRound(levelMapCategory, win);
      await pumpEventQueue(); // Riverpod avisa a los listeners en diferido.

      expect(updates, hasLength(1));
      expect(currentLevel(), 2);
      expect(
        container.read(levelMapProvider).first,
        const LevelNode(number: 1, status: LevelStatus.completed),
      );
    });

    test('perder no desbloquea nada', () async {
      container.listen(levelMapProvider, (_, _) {});
      await pumpEventQueue();

      container
          .read(adaptiveDifficultyProvider.notifier)
          .recordRound(
            levelMapCategory,
            const RoundPerformance(
              pairCount: 6,
              matchedPairs: 2,
              memoryErrors: 5,
              hintsUsed: 0,
              secondsRemaining: 0,
              timeLimitSeconds: 120,
              won: false,
            ),
          );

      expect(currentLevel(), 1);
    });

    test('otra categoría no mueve el mapa', () async {
      container.listen(levelMapProvider, (_, _) {});
      await pumpEventQueue();

      container
          .read(adaptiveDifficultyProvider.notifier)
          .recordRound(GameCategories.numeric, win);

      expect(currentLevel(), 1);
    });

    test('el progreso guardado en Drift se ve al reabrir la app', () async {
      await SkillRepository(database: db).save(
        levelMapCategory.id,
        const SkillState(skill: 0.4, pairCount: 6, level: 5),
      );
      // Como una app recién abierta: un contenedor nuevo sobre la misma base.
      container.dispose();
      container = buildContainer();

      container.listen(levelMapProvider, (_, _) {});
      await pumpEventQueue();

      expect(currentLevel(), 5);
      expect(
        container
            .read(levelMapProvider)
            .where((n) => n.number < 5)
            .every((n) => n.status == LevelStatus.completed),
        isTrue,
      );
    });
  });
}
