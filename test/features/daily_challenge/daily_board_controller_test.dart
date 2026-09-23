import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/daily_challenge/model/daily_challenge.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/game/controller/game_controller.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';

class _FakeGameController extends GameController {
  @override
  Future<void> completeSoloGame({
    required int score,
    required int moves,
    required int secondsElapsed,
    required int timeLimit,
    required bool won,
    int currentLevel = 1,
  }) async {}
}

void main() {
  final challenge = DailyChallenge.forDate(DateTime(2026, 9, 23));
  final setup = (challenge: challenge, languageCode: 'es');

  ProviderContainer buildContainer() => ProviderContainer(
    overrides: [
      // A random the daily board must ignore: if it leaked in, two
      // containers would deal different boards.
      boardRandomProvider.overrideWith((_) => Random()),
      gameControllerProvider.overrideWith(_FakeGameController.new),
      displayPreferencesProvider.overrideWithValue(DisplayPreferences.defaults),
    ],
  );

  test('dos dispositivos reciben el mismo tablero', () {
    final a = buildContainer();
    final b = buildContainer();
    addTearDown(a.dispose);
    addTearDown(b.dispose);

    List<String> pairs(ProviderContainer c) => [
      for (final card in c.read(dailyBoardControllerProvider(setup)).cards)
        card.pairId,
    ];

    expect(pairs(a), pairs(b));
    expect(pairs(a), hasLength(DailyChallenge.pairCount * 2));
  });

  test('sin cuenta atrás, cuenta volteos y no toca la dificultad', () {
    fakeAsync((async) {
      final container = buildContainer();
      addTearDown(container.dispose);
      final provider = dailyBoardControllerProvider(setup);
      container.listen(provider, (_, _) {});

      // Aunque el jugador tenga el reloj activado.
      expect(container.read(provider).isTimed, isFalse);

      async.elapse(Duration(seconds: challenge.settings.previewSeconds));
      final cards = container.read(provider).cards;
      final first = 0;
      final partner = cards.indexWhere(
        (c) => c.pairId == cards[first].pairId,
        1,
      );
      final other = cards.indexWhere((c) => c.pairId != cards[first].pairId);

      // Un fallo y luego el acierto: la primera carta se voltea dos veces.
      container.read(provider.notifier).flipCard(first);
      container.read(provider.notifier).flipCard(other);
      async.elapse(const Duration(seconds: 3));
      container.read(provider.notifier).flipCard(first);
      container.read(provider.notifier).flipCard(partner);
      async.elapse(const Duration(seconds: 1));

      final after = container.read(provider).cards;
      expect(after[first].flipCount, 2);
      expect(after[partner].flipCount, 1);
      expect(after[first].isMatched, isTrue);

      // Resolver el resto para terminar el tablero.
      final remaining = <String, List<int>>{};
      for (var i = 0; i < after.length; i++) {
        if (!after[i].isMatched) {
          remaining.putIfAbsent(after[i].pairId, () => []).add(i);
        }
      }
      for (final pair in remaining.values) {
        container.read(provider.notifier).flipCard(pair[0]);
        container.read(provider.notifier).flipCard(pair[1]);
        async.elapse(const Duration(seconds: 1));
      }

      expect(container.read(provider).isCompleted, isTrue);
      expect(
        container.read(adaptiveDifficultyProvider),
        isEmpty,
        reason: 'el tablero diario no debe entrenar la dificultad adaptativa',
      );
    });
  });
}
