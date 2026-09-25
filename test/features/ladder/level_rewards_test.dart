import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/ladder/level_rewards.dart';

void main() {
  group('forCompletedLevel', () {
    test('solo los múltiplos de 5 tienen premio', () {
      for (final level in [0, 1, 2, 3, 4, 6, 7, 9, 11, 14]) {
        expect(LevelRewards.forCompletedLevel(level), isNull, reason: '$level');
      }
      expect(LevelRewards.forCompletedLevel(5), isNotNull);
      expect(LevelRewards.forCompletedLevel(15), isNotNull);
    });

    test('cada 5 niveles un regalo, cada 10 un cofre que vale el doble', () {
      expect(
        LevelRewards.forCompletedLevel(5),
        const LevelReward(level: 5, coins: 100, isChest: false),
      );
      expect(
        LevelRewards.forCompletedLevel(10),
        const LevelReward(level: 10, coins: 400, isChest: true),
      );
      expect(
        LevelRewards.forCompletedLevel(15),
        const LevelReward(level: 15, coins: 300, isChest: false),
      );
    });
  });

  group('between', () {
    test('entrega los peldaños del tramo, sin repetir el ya cobrado', () {
      expect(LevelRewards.between(after: 5, upTo: 12).map((r) => r.level), [
        10,
      ]);
      expect(LevelRewards.between(after: 0, upTo: 20).map((r) => r.level), [
        5,
        10,
        15,
        20,
      ]);
    });

    test('un tramo vacío o invertido no paga nada', () {
      expect(LevelRewards.between(after: 5, upTo: 5), isEmpty);
      expect(LevelRewards.between(after: 7, upTo: 3), isEmpty);
    });
  });

  group('siguiente premio', () {
    test('un jugador nuevo va a por el del nivel 5', () {
      expect(LevelRewards.nextAfter(0).level, 5);
      expect(LevelRewards.levelsUntilNext(0), 5);
      expect(LevelRewards.progressTowardsNext(0), 0.0);
    });

    test('con 6 niveles completados apunta al cofre del 10', () {
      expect(LevelRewards.nextAfter(6).level, 10);
      expect(LevelRewards.nextAfter(6).isChest, isTrue);
      expect(LevelRewards.levelsUntilNext(6), 4);
      expect(LevelRewards.progressTowardsNext(6), closeTo(0.2, 1e-9));
    });

    test('justo al cobrar un premio el siguiente queda a 5 niveles', () {
      expect(LevelRewards.nextAfter(5).level, 10);
      expect(LevelRewards.levelsUntilNext(5), 5);
      expect(LevelRewards.progressTowardsNext(5), 0.0);
    });
  });
}
