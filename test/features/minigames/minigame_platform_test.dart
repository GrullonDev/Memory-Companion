import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';
import 'package:memory_companion/features/minigames/modules/memory/memory_game_module.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';

/// Un juego mínimo, con todos los valores por defecto del contrato.
class _SequenceGame extends BaseMinigame {
  const _SequenceGame();

  @override
  String get id => 'sequence';
  @override
  String get titleKey => AppLocale.minigameMemoryTitle;
  @override
  String get descriptionKey => AppLocale.minigameMemoryDescription;
  @override
  IconData get icon => Icons.pin_rounded;
  @override
  MinigamePalette get palette => MinigamePalette.sky;
  @override
  Widget buildGameScreen() => const Text('sequence screen');
}

void main() {
  group('registro', () {
    test('ids, rutas y claves de estadísticas no se pisan', () {
      final games = MinigameRegistry.all;
      expect(games.map((g) => g.id).toSet(), hasLength(games.length));
      expect(games.map((g) => g.routeName).toSet(), hasLength(games.length));
      for (final game in games) {
        final key = game.statsKeyFor(null);
        expect(game.ownsStatsKey(key), isTrue, reason: game.id);
        expect(games.where((other) => other.ownsStatsKey(key)), [
          game,
        ], reason: '${game.id} comparte clave de estadísticas');
      }
    });

    test('la memoria sigue en su ruta y con las claves de siempre', () {
      const memory = MemoryGameModule();
      expect(memory.routeName, RoutePaths.boardSolo);
      expect(
        MinigameRegistry.byRoute(RoutePaths.boardSolo),
        isA<MemoryGameModule>(),
      );
      for (final category in GameCategories.all) {
        expect(memory.statsKeyFor(category.id), category.id);
        expect(
          MinigameRegistry.ownerOfStatsKey(category.id),
          isA<MemoryGameModule>(),
        );
      }
      expect(memory.statsKeyFor(null), GameCategories.classic.id);
    });

    test('la ruta generada conserva los argumentos', () {
      final route = MinigameRegistry.routeFor(
        const RouteSettings(name: RoutePaths.boardSolo, arguments: 'numeric'),
      );
      expect(route?.settings.arguments, 'numeric');
      expect(
        MinigameRegistry.routeFor(const RouteSettings(name: '/nope')),
        isNull,
      );
    });

    test('un juego nuevo usa claves con espacio de nombres', () {
      const game = _SequenceGame();
      expect(game.routeName, '/games/sequence');
      expect(game.statsKeyFor(null), 'sequence');
      expect(game.statsKeyFor('reverse'), 'sequence:reverse');
      expect(game.ownsStatsKey('sequence:reverse'), isTrue);
      expect(game.ownsStatsKey('sequences'), isFalse);
    });
  });

  group('reporter', () {
    late AppDatabase db;
    late StatsRepository repository;
    late MinigameResultReporter reporter;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = StatsRepository(database: db);
      reporter = MinigameResultReporter(
        repository: repository,
        clock: () => DateTime(2026, 9, 23, 10),
      );
    });

    tearDown(() => db.close());

    test('traduce el resultado a una fila de game_stats', () async {
      await reporter.report(
        const _SequenceGame(),
        const MinigameResult(
          variantId: 'reverse',
          itemCount: 7,
          itemsSolved: 5,
          attempts: 8,
          errors: 3,
          secondsElapsed: 42,
          won: false,
          score: 300,
        ),
      );

      final [game] = await repository.recentGames();
      expect(game.categoryId, 'sequence:reverse');
      expect(game.pairCount, 7);
      expect(game.matchedPairs, 5);
      expect(game.moves, 8);
      expect(game.memoryErrors, 3);
      expect(game.timeSeconds, 42);
      expect(game.timed, isFalse);
      expect(game.won, isFalse);
      expect(game.date, DateTime(2026, 9, 23, 10));
      expect(game.accuracy, 5 / 8);
    });

    test('un fallo de disco no llega al juego', () async {
      await db.close();
      await expectLater(
        reporter.report(
          const _SequenceGame(),
          const MinigameResult(
            itemCount: 1,
            itemsSolved: 1,
            attempts: 1,
            secondsElapsed: 1,
            won: true,
            score: 1,
          ),
        ),
        completes,
      );
    });
  });
}
