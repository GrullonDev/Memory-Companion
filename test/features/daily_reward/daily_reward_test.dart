import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/daily_reward/model/daily_reward.dart';
import 'package:memory_companion/features/daily_reward/repository/daily_reward_repository.dart';
import 'package:memory_companion/features/daily_reward/widget/daily_reward_card.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

void main() {
  group('DailyRewardSchedule', () {
    test('el multiplicador sube 0.25 por día y se queda en x3', () {
      expect(DailyRewardSchedule.multiplierFor(1), 1);
      expect(DailyRewardSchedule.multiplierFor(2), 1.25);
      expect(DailyRewardSchedule.multiplierFor(5), 2);
      expect(DailyRewardSchedule.multiplierFor(9), 3);
      expect(DailyRewardSchedule.multiplierFor(40), 3);
    });

    test('el premio escala la base con el multiplicador', () {
      final day1 = DailyRewardSchedule.rewardFor(1, dateKey: '2026-09-29');
      expect(day1.coins, DailyRewardSchedule.baseCoins);
      expect(day1.xp, DailyRewardSchedule.baseXp);
      expect(day1.isChestDay, isFalse);

      final day5 = DailyRewardSchedule.rewardFor(5, dateKey: '2026-09-29');
      expect(day5.coins, DailyRewardSchedule.baseCoins * 2);
    });

    test('cada 7 días hay cofre, y la sorpresa no cambia al reabrir', () {
      final chest = DailyRewardSchedule.rewardFor(7, dateKey: '2026-09-29');
      expect(chest.isChestDay, isTrue);
      expect(chest.chestAmount, greaterThan(0));
      expect(
        chest.totalCoins + chest.totalXp,
        chest.coins + chest.xp + chest.chestAmount,
      );

      final again = DailyRewardSchedule.rewardFor(7, dateKey: '2026-09-29');
      expect(again.chestBonus, chest.chestBonus);
      expect(again.chestAmount, chest.chestAmount);
    });

    test('la etiqueta del multiplicador no lleva ceros de sobra', () {
      expect(multiplierLabel(1), 'x1');
      expect(multiplierLabel(1.25), 'x1.25');
      expect(multiplierLabel(1.5), 'x1.5');
      expect(multiplierLabel(3), 'x3');
    });
  });

  group('DailyRewardStatus', () {
    final today = DateTime(2026, 9, 29, 10);

    test('sin reclamar nunca: disponible, día 1', () {
      final status = DailyRewardStatus.resolve(
        lastClaimDate: null,
        claimStreak: 0,
        now: today,
      );
      expect(status.available, isTrue);
      expect(status.streak, 1);
      expect(status.weekDays, [1, 2, 3, 4, 5, 6, 7]);
    });

    test('reclamado ayer: disponible y la racha sigue', () {
      final status = DailyRewardStatus.resolve(
        lastClaimDate: '2026-09-28',
        claimStreak: 7,
        now: today,
      );
      expect(status.available, isTrue);
      expect(status.streak, 8);
      expect(status.weekDays.first, 8, reason: 'empieza la segunda semana');
    });

    test('reclamado hoy: nada que reclamar, enseña el de mañana', () {
      final status = DailyRewardStatus.resolve(
        lastClaimDate: '2026-09-29',
        claimStreak: 3,
        now: today,
      );
      expect(status.available, isFalse);
      expect(status.streak, 3);
      expect(status.reward.day, 4);
    });

    test('un día perdido reinicia la racha', () {
      final status = DailyRewardStatus.resolve(
        lastClaimDate: '2026-09-26',
        claimStreak: 12,
        now: today,
      );
      expect(status.available, isTrue);
      expect(status.streak, 1);
    });

    test('con el reloj hacia atrás no se regala nada', () {
      final status = DailyRewardStatus.resolve(
        lastClaimDate: '2026-10-05',
        claimStreak: 4,
        now: today,
      );
      expect(status.available, isFalse);
    });
  });

  group('DailyRewardRepository', () {
    late AppDatabase db;
    late DateTime now;
    late PlayerRepository players;
    late DailyRewardRepository rewards;
    late String localId;
    var ids = 0;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      now = DateTime(2026, 9, 29, 10);
      players = PlayerRepository(
        database: db,
        syncQueue: SyncQueue(database: db),
        idGenerator: () => 'id-${++ids}',
        clock: () => now,
      );
      rewards = DailyRewardRepository(
        database: db,
        playerRepository: players,
        clock: () => now,
      );
      localId = (await players.ensureLocalProfile()).localId;
    });

    tearDown(() => db.close());

    test('reclamar paga monedas y XP una sola vez al día', () async {
      final claim = await rewards.claim(playerLocalId: localId);
      expect(claim, isNotNull);
      expect(claim!.streak, 1);

      final profile = await players.readLocalProfile();
      expect(profile!.totalCoins, claim.reward.totalCoins);
      expect(profile.totalXp, claim.reward.totalXp);

      expect(await rewards.claim(playerLocalId: localId), isNull);
      expect(
        (await players.readLocalProfile())!.totalCoins,
        claim.reward.totalCoins,
        reason: 'el segundo reclamo del día no paga',
      );
    });

    test('días seguidos suben la racha y el multiplicador', () async {
      await rewards.claim(playerLocalId: localId);
      now = now.add(const Duration(days: 1));
      final second = await rewards.claim(playerLocalId: localId);
      expect(second!.streak, 2);
      expect(second.reward.multiplier, 1.25);

      final row = await db.select(db.dailyRewards).getSingle();
      expect(row.claimStreak, 2);
      expect(row.longestClaimStreak, 2);
      expect(row.totalClaims, 2);
    });

    test('las monedas y el XP se encolan como incrementos', () async {
      final claim = await rewards.claim(playerLocalId: localId);
      final ops = await db.select(db.syncOperations).get();
      final byType = {for (final op in ops) op.type: op.payloadJson};
      expect(
        byType.keys,
        containsAll([SyncOperationType.earnCoins, SyncOperationType.addXp]),
      );
      expect(
        byType[SyncOperationType.addXp],
        contains('${claim!.reward.totalXp}'),
      );
    });

    test('el estado se actualiza solo al reclamar', () async {
      final statuses = rewards.watchStatus(localId);
      expect((await statuses.first).available, isTrue);
      await rewards.claim(playerLocalId: localId);
      expect((await statuses.first).available, isFalse);
    });
  });
}
