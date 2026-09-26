import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/game/model/match_rewards.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';

/// Skips Firebase: the board only needs the call to not throw.
class _FakeGameController extends GameController {
  @override
  Future<void> completeSoloGame({
    required String matchId,
    required int score,
    required int moves,
    required int secondsElapsed,
    required int timeLimit,
    required bool won,
    required MatchRewards rewards,
    int? levelNumber,
  }) async {}
}

void main() {
  // Cada contenedor lleva su propia base en memoria, y algunos grupos
  // construyen uno nuevo antes de cerrar el anterior: es a propósito.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const setup = (category: GameCategories.numeric, languageCode: 'es');

  late ProviderContainer container;

  ProviderContainer buildContainer({
    DisplayPreferences preferences = DisplayPreferences.defaults,
  }) {
    // Las estadísticas se guardan al terminar cada partida: en memoria, no
    // en el disco del equipo que corre los tests.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    return ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        boardRandomProvider.overrideWithValue(Random(7)),
        gameControllerProvider.overrideWith(_FakeGameController.new),
        // Sin esto las preferencias saldrían de la base real del dispositivo.
        displayPreferencesProvider.overrideWithValue(preferences),
      ],
    );
  }

  setUp(() {
    container = buildContainer();
  });

  tearDown(() => container.dispose());

  BoardState state() => container.read(boardControllerProvider(setup));
  BoardController controller() =>
      container.read(boardControllerProvider(setup).notifier);

  /// Pairs of card indexes that match, in board order.
  List<(int, int)> pairIndexes() {
    final cards = state().cards;
    final result = <(int, int)>[];
    for (var i = 0; i < cards.length; i++) {
      final j = cards.indexWhere((c) => c.pairId == cards[i].pairId, i + 1);
      if (j != -1) result.add((i, j));
    }
    return result;
  }

  test('reparte según la dificultad adaptativa y empieza con vista previa', () {
    fakeAsync((async) {
      container.listen(boardControllerProvider(setup), (_, _) {});
      final expected = container
          .read(adaptiveDifficultyProvider.notifier)
          .settingsFor(GameCategories.numeric);

      expect(state().pairCount, expected.pairCount);
      expect(state().totalSeconds, expected.timeLimitSeconds);
      expect(state().isPreviewing, isTrue);
      expect(state().cards.every((c) => c.isFaceUp), isTrue);

      // Durante la vista previa no se puede jugar ni corre el reloj.
      controller().flipCard(0);
      expect(state().moves, 0);

      async.elapse(Duration(seconds: expected.previewSeconds));
      expect(state().isPreviewing, isFalse);
      expect(state().cards.every((c) => !c.isFaceUp), isTrue);
      expect(state().secondsRemaining, expected.timeLimitSeconds);
    });
  });

  test('ganar registra la ronda y el siguiente tablero ya es más grande', () {
    fakeAsync((async) {
      container.listen(boardControllerProvider(setup), (_, _) {});
      async.elapse(Duration(seconds: state().previewSecondsRemaining));

      // Varias rondas perfectas: el tablero debe crecer poco a poco.
      final sizes = <int>[state().pairCount];
      for (var round = 0; round < 12; round++) {
        for (final (a, b) in pairIndexes()) {
          controller()
            ..flipCard(a)
            ..flipCard(b);
          async.elapse(const Duration(seconds: 1));
        }
        expect(state().isCompleted, isTrue);
        expect(state().won, isTrue);

        controller().restart();
        sizes.add(state().pairCount);
        async.elapse(Duration(seconds: state().previewSecondsRemaining));
      }

      expect(sizes.last, greaterThan(sizes.first));
      for (var i = 1; i < sizes.length; i++) {
        expect(sizes[i] - sizes[i - 1], inInclusiveRange(0, 1));
      }
      expect(
        container
            .read(adaptiveDifficultyProvider)[GameCategories.numeric.id]!
            .roundsPlayed,
        12,
      );
    });
  });

  test('cada 5 niveles ganados el tablero anuncia y entrega un premio', () {
    fakeAsync((async) {
      container.listen(boardControllerProvider(setup), (_, _) {});
      async.elapse(Duration(seconds: state().previewSecondsRemaining));

      final announced = <int?>[];
      for (var round = 0; round < 5; round++) {
        expect(state().level, round + 1);
        for (final (a, b) in pairIndexes()) {
          controller()
            ..flipCard(a)
            ..flipCard(b);
          async.elapse(const Duration(seconds: 1));
        }
        expect(state().won, isTrue);
        announced.add(state().levelReward?.level);

        controller().nextLevel();
        async.elapse(Duration(seconds: state().previewSecondsRemaining));
      }

      // Solo el Nivel 5 es peldaño de premio.
      expect(announced, [null, null, null, null, 5]);
      expect(state().level, 6);

      // Y las monedas llegan de verdad al saldo local.
      async.elapse(const Duration(seconds: 1));
      int? coins;
      container
          .read(playerRepositoryProvider)
          .readLocalProfile()
          .then((p) => coins = p?.totalCoins);
      async.elapse(const Duration(seconds: 1));
      expect(coins, 100);
    });
  });

  test('cada partida terminada se guarda en las estadísticas locales', () {
    fakeAsync((async) {
      container.listen(boardControllerProvider(setup), (_, _) {});
      async.elapse(Duration(seconds: state().previewSecondsRemaining));

      final pairs = pairIndexes();
      // Un fallo primero: la precisión no debe salir perfecta.
      controller()
        ..flipCard(pairs[0].$1)
        ..flipCard(pairs[1].$1);
      async.elapse(const Duration(seconds: 3));
      for (final (a, b) in pairs) {
        controller()
          ..flipCard(a)
          ..flipCard(b);
        async.elapse(const Duration(seconds: 1));
      }
      expect(state().won, isTrue);

      final repository = container.read(statsRepositoryProvider);
      final games = <GameStats>[];
      repository.recentGames().then(games.addAll);
      async.flushMicrotasks();

      expect(games, hasLength(1));
      final game = games.single;
      expect(game.won, isTrue);
      expect(game.categoryId, GameCategories.numeric.id);
      expect(game.pairCount, state().pairCount);
      expect(game.matchedPairs, state().pairCount);
      expect(game.moves, state().pairCount + 1);
      expect(game.accuracy, lessThan(1));
      expect(game.timeSeconds, state().elapsedSeconds);
    });
  });

  test('un fallo se oculta tras el tiempo de revelación de la dificultad', () {
    fakeAsync((async) {
      container.listen(boardControllerProvider(setup), (_, _) {});
      async.elapse(Duration(seconds: state().previewSecondsRemaining));

      final [(a, _), (c, _), ...] = pairIndexes();
      controller()
        ..flipCard(a)
        ..flipCard(c);
      expect(state().moves, 1);

      async.elapse(const Duration(milliseconds: 500));
      expect(state().cards[a].isFaceUp, isTrue, reason: 'aún a la vista');

      async.elapse(const Duration(seconds: 2));
      expect(state().cards[a].isFaceUp, isFalse);
      expect(state().cards[c].isFaceUp, isFalse);
    });
  });

  test('reiniciar durante un fallo pendiente no toca el tablero nuevo', () {
    fakeAsync((async) {
      container.listen(boardControllerProvider(setup), (_, _) {});
      async.elapse(Duration(seconds: state().previewSecondsRemaining));

      final [(a, _), (c, _), ...] = pairIndexes();
      controller()
        ..flipCard(a)
        ..flipCard(c);
      controller().restart();
      final fresh = state().cards;

      async.elapse(const Duration(seconds: 3));
      expect(state().moves, 0);
      expect(
        [for (final card in state().cards) card.pairId],
        [for (final card in fresh) card.pairId],
      );
    });
  });

  group('perfil accesible', () {
    const accessible = DisplayPreferences(
      visualProfile: VisualProfile.accessible,
      timedMatches: false,
    );

    setUp(() {
      container.dispose();
      container = buildContainer(preferences: accessible);
    });

    test('sin reloj, agotar el tiempo no termina la partida', () {
      fakeAsync((async) {
        container.listen(boardControllerProvider(setup), (_, _) {});
        async.elapse(Duration(seconds: state().previewSecondsRemaining));
        final limit = state().totalSeconds;

        expect(state().isTimed, isFalse);
        async.elapse(Duration(seconds: limit + 30));

        expect(state().isCompleted, isFalse);
        expect(state().secondsRemaining, 0);
        expect(
          state().elapsedSeconds,
          limit + 30,
          reason: 'el resultado muestra el tiempo real, no el límite',
        );
      });
    });

    test('sin reloj, la partida se sigue pudiendo ganar', () {
      fakeAsync((async) {
        container.listen(boardControllerProvider(setup), (_, _) {});
        async.elapse(Duration(seconds: state().previewSecondsRemaining));
        async.elapse(Duration(seconds: state().totalSeconds + 5));

        for (final (a, b) in pairIndexes()) {
          controller()
            ..flipCard(a)
            ..flipCard(b);
          async.elapse(const Duration(seconds: 1));
        }

        expect(state().isCompleted, isTrue);
        expect(state().won, isTrue);
      });
    });

    test('un fallo queda a la vista al menos el mínimo del perfil', () {
      fakeAsync((async) {
        container.listen(boardControllerProvider(setup), (_, _) {});
        async.elapse(Duration(seconds: state().previewSecondsRemaining));

        final [(a, _), (c, _), ...] = pairIndexes();
        controller()
          ..flipCard(a)
          ..flipCard(c);

        async.elapse(
          accessible.mismatchRevealFloor - const Duration(milliseconds: 1),
        );
        expect(state().cards[a].isFaceUp, isTrue);
        expect(state().cards[c].isFaceUp, isTrue);

        async.elapse(const Duration(seconds: 3));
        expect(state().cards[a].isFaceUp, isFalse);
      });
    });
  });
}
