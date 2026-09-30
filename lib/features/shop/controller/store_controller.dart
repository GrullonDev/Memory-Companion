import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/lives/controller/lives_controller.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/shop/model/store_item.dart';
import 'package:memory_companion/features/shop/repository/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(
    database: ref.watch(appDatabaseProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
  ),
);

/// What the player holds, live. Empty while the profile loads.
final inventoryProvider = StreamProvider<Map<InventoryKind, int>>((ref) async* {
  final player = await ref.watch(localPlayerProvider.future);
  yield* ref.watch(inventoryRepositoryProvider).watch(player.localId);
});

/// Buys and spends store items for the local player.
///
/// Never throws: a failed write reads as "not bought" and nothing is lost.
class StoreService {
  StoreService(this._ref);

  final Ref _ref;

  Future<String> _playerId() async =>
      (await _ref.read(playerRepositoryProvider).ensureLocalProfile()).localId;

  Future<PurchaseResult> buy(StoreItem item) async {
    try {
      if (item.grants == null) return await _buyNow(item);
      return await _ref
          .read(inventoryRepositoryProvider)
          .purchase(playerLocalId: await _playerId(), item: item);
    } catch (e, stack) {
      debugPrint('Error buying ${item.name}: $e\n$stack');
      return PurchaseResult.notNeeded;
    }
  }

  /// Items that act at once. Only the lives refill, for now: charged only
  /// when there are lives to fill, and refunded if filling them fails.
  Future<PurchaseResult> _buyNow(StoreItem item) async {
    assert(item == StoreItem.livesRefill);
    final lives = _ref.read(livesControllerProvider.notifier);
    final current = await _ref.read(livesControllerProvider.future);
    if (lives.hasInfiniteLives || current.current >= current.max) {
      return PurchaseResult.notNeeded;
    }
    final playerId = await _playerId();
    final players = _ref.read(playerRepositoryProvider);
    final paid = await players.spendCoins(
      localId: playerId,
      amount: item.price,
    );
    if (!paid) return PurchaseResult.notEnoughCoins;
    if (!await lives.refill()) {
      await players.earnCoins(localId: playerId, amount: item.price);
      return PurchaseResult.notNeeded;
    }
    return PurchaseResult.purchased;
  }

  /// Spends one [kind] from the inventory. `false` when there is none.
  Future<bool> use(InventoryKind kind) async {
    try {
      return await _ref
          .read(inventoryRepositoryProvider)
          .consume(await _playerId(), kind);
    } catch (e, stack) {
      debugPrint('Error using ${kind.name}: $e\n$stack');
      return false;
    }
  }
}

final storeServiceProvider = Provider<StoreService>(StoreService.new);
