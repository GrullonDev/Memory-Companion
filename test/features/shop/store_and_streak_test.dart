import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';
import 'package:memory_companion/features/player/model/player_streak.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';
import 'package:memory_companion/features/shop/model/store_item.dart';
import 'package:memory_companion/features/shop/repository/inventory_repository.dart';

void main() {
  group('advanceStreak con protectores', () {
    final monday = DateTime(2026, 9, 28, 10);

    test('un día perdido se cubre con un protector y la racha sigue', () {
      final update = advanceStreak(
        lastPlayedDate: '2026-09-26',
        currentStreak: 5,
        longestStreak: 5,
        now: monday,
        availableFreezes: 1,
      );
      expect(update.currentStreak, 6);
      expect(update.freezesUsed, 1);
    });

    test('sin protectores suficientes la racha vuelve a 1 sin gastar nada', () {
      final update = advanceStreak(
        lastPlayedDate: '2026-09-25',
        currentStreak: 5,
        longestStreak: 5,
        now: monday,
        availableFreezes: 1,
      );
      expect(update.currentStreak, 1);
      expect(update.freezesUsed, 0);
    });

    test('jugar ayer no gasta protectores', () {
      final update = advanceStreak(
        lastPlayedDate: '2026-09-27',
        currentStreak: 2,
        longestStreak: 2,
        now: monday,
        availableFreezes: 3,
      );
      expect(update.currentStreak, 3);
      expect(update.freezesUsed, 0);
    });
  });

  group('premios de racha', () {
    test('cada día paga más hasta la semana, y los hitos pagan extra', () {
      expect(streakDayCoins(0), 0);
      expect(streakDayCoins(1), 10);
      expect(streakDayCoins(2), 20);
      expect(streakDayCoins(3), 30 + 60, reason: 'hito del día 3');
      expect(streakDayCoins(8), 70);
      expect(streakDayCoins(150), 70 + 3000, reason: 'un hito cada 50');
    });

    test('siempre hay un hito por delante', () {
      for (var day = 0; day < 400; day++) {
        expect(nextStreakMilestone(day), greaterThan(day));
        expect(isStreakMilestone(nextStreakMilestone(day)), isTrue);
      }
    });

    test('la racha que se ve distingue hoy, en riesgo y rota', () {
      final now = DateTime(2026, 9, 30, 12);
      expect(
        streakStatusAt(
          lastPlayedDate: '2026-09-30',
          currentStreak: 4,
          now: now,
        ),
        (status: StreakStatus.safe, days: 4),
      );
      expect(
        streakStatusAt(
          lastPlayedDate: '2026-09-29',
          currentStreak: 4,
          now: now,
        ),
        (status: StreakStatus.atRisk, days: 4),
      );
      expect(
        streakStatusAt(
          lastPlayedDate: '2026-09-27',
          currentStreak: 4,
          now: now,
        ),
        (status: StreakStatus.none, days: 0),
      );
      expect(
        streakStatusAt(
          lastPlayedDate: '2026-09-27',
          currentStreak: 4,
          now: now,
          availableFreezes: 2,
        ),
        (status: StreakStatus.atRisk, days: 4),
      );
    });
  });

  group('tienda e inventario', () {
    late AppDatabase db;
    late PlayerRepository players;
    late InventoryRepository inventory;
    late PlayerProfile player;
    late DateTime now;

    setUp(() async {
      var ids = 0;
      db = AppDatabase.forTesting(NativeDatabase.memory());
      now = DateTime(2026, 9, 20, 10);
      players = PlayerRepository(
        database: db,
        syncQueue: SyncQueue(database: db),
        idGenerator: () => 'id-${++ids}',
        clock: () => now,
      );
      inventory = InventoryRepository(
        database: db,
        playerRepository: players,
        clock: () => now,
      );
      player = await players.ensureLocalProfile();
    });

    tearDown(() => db.close());

    Future<int> coins() async => (await players.readLocalProfile())!.totalCoins;

    test('comprar cobra y entrega en la misma operación', () async {
      await players.earnCoins(localId: player.localId, amount: 200);

      final result = await inventory.purchase(
        playerLocalId: player.localId,
        item: StoreItem.hintPack,
      );

      expect(result, PurchaseResult.purchased);
      expect(await coins(), 200 - StoreItem.hintPack.price);
      expect(
        await inventory.quantityOf(player.localId, InventoryKind.hint),
        StoreItem.hintPack.quantity,
      );
    });

    test('sin saldo no se cobra ni se entrega nada', () async {
      await players.earnCoins(localId: player.localId, amount: 10);

      final result = await inventory.purchase(
        playerLocalId: player.localId,
        item: StoreItem.streakFreeze,
      );

      expect(result, PurchaseResult.notEnoughCoins);
      expect(await coins(), 10);
      expect(
        await inventory.quantityOf(player.localId, InventoryKind.streakFreeze),
        0,
      );
    });

    test('no se pueden acumular más protectores que el máximo', () async {
      await players.earnCoins(localId: player.localId, amount: 10000);
      for (var i = 0; i < StoreItem.streakFreeze.maxOwned!; i++) {
        await inventory.purchase(
          playerLocalId: player.localId,
          item: StoreItem.streakFreeze,
        );
      }
      final before = await coins();

      final result = await inventory.purchase(
        playerLocalId: player.localId,
        item: StoreItem.streakFreeze,
      );

      expect(result, PurchaseResult.limitReached);
      expect(await coins(), before);
    });

    test('gastar un artículo que no hay no hace nada', () async {
      expect(
        await inventory.consume(player.localId, InventoryKind.hint),
        isFalse,
      );
      await inventory.add(player.localId, InventoryKind.hint, 1);
      expect(
        await inventory.consume(player.localId, InventoryKind.hint),
        isTrue,
      );
      expect(await inventory.quantityOf(player.localId, InventoryKind.hint), 0);
    });

    test('un protector comprado salva la racha tras faltar un día', () async {
      await players.registerPlayedToday(localId: player.localId); // día 1
      now = now.add(const Duration(days: 1));
      await players.registerPlayedToday(localId: player.localId); // día 2
      await inventory.add(player.localId, InventoryKind.streakFreeze, 1);

      now = now.add(const Duration(days: 2)); // falta un día
      final streak = await players.registerPlayedToday(localId: player.localId);

      expect(streak!.currentStreak, 3);
      expect(streak.freezesUsed, 1);
      expect(
        await inventory.quantityOf(player.localId, InventoryKind.streakFreeze),
        0,
      );
    });

    test(
      'la primera partida de cada día paga la racha, la segunda no',
      () async {
        final first = await players.registerPlayedToday(
          localId: player.localId,
        );
        final second = await players.registerPlayedToday(
          localId: player.localId,
        );

        expect(first!.bonusCoins, streakDayCoins(1));
        expect(second!.bonusCoins, 0);
        expect(await coins(), streakDayCoins(1));

        now = now.add(const Duration(days: 1));
        final nextDay = await players.registerPlayedToday(
          localId: player.localId,
        );
        expect(nextDay!.bonusCoins, streakDayCoins(2));
        expect(await coins(), streakDayCoins(1) + streakDayCoins(2));
      },
    );
  });
}
