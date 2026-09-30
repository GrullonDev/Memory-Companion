import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';
import 'package:memory_companion/features/shop/model/store_item.dart';

/// Lo que el jugador tiene comprado, y la compra en sí.
///
/// Comprar descuenta las monedas y añade el artículo **en la misma
/// transacción**: no puede cobrarse sin entregarse ni entregarse sin
/// cobrarse, y dos compras simultáneas no pueden pasar del saldo.
class InventoryRepository {
  InventoryRepository({
    required AppDatabase database,
    required PlayerRepository playerRepository,
    DateTime Function()? clock,
  }) : _db = database,
       _playerRepository = playerRepository,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final PlayerRepository _playerRepository;
  final DateTime Function() _now;

  /// Cantidades por artículo, en vivo. Lo que nunca se compró no aparece.
  Stream<Map<InventoryKind, int>> watch(String playerLocalId) {
    final query = _db.select(_db.inventoryItems)
      ..where((i) => i.playerLocalId.equals(playerLocalId));
    return query.watch().map(_toMap);
  }

  Future<int> quantityOf(String playerLocalId, InventoryKind kind) async {
    final row = await _select(playerLocalId, kind);
    return row?.quantity ?? 0;
  }

  /// Compra [item] con las monedas del jugador y añade lo que da al
  /// inventario. Solo para artículos que se guardan ([StoreItem.grants]).
  Future<PurchaseResult> purchase({
    required String playerLocalId,
    required StoreItem item,
  }) {
    final kind = item.grants;
    assert(kind != null, '${item.name} takes effect at once');
    if (kind == null) return Future.value(PurchaseResult.notNeeded);
    return _db.transaction(() async {
      final owned = (await _select(playerLocalId, kind))?.quantity ?? 0;
      final max = item.maxOwned;
      if (max != null && owned >= max) return PurchaseResult.limitReached;

      final paid = await _playerRepository.spendCoins(
        localId: playerLocalId,
        amount: item.price,
      );
      if (!paid) return PurchaseResult.notEnoughCoins;

      await _write(playerLocalId, kind, owned + item.quantity);
      return PurchaseResult.purchased;
    });
  }

  /// Añade [amount] de [kind] sin cobrar: premios, regalos.
  Future<void> add(String playerLocalId, InventoryKind kind, int amount) {
    return _db.transaction(() async {
      if (amount <= 0) return;
      final owned = (await _select(playerLocalId, kind))?.quantity ?? 0;
      await _write(playerLocalId, kind, owned + amount);
    });
  }

  /// Gasta [amount] de [kind]. Devuelve `false` —sin tocar nada— si no hay.
  Future<bool> consume(
    String playerLocalId,
    InventoryKind kind, {
    int amount = 1,
  }) {
    return _db.transaction(() async {
      final owned = (await _select(playerLocalId, kind))?.quantity ?? 0;
      if (amount <= 0 || owned < amount) return false;
      await _write(playerLocalId, kind, owned - amount);
      return true;
    });
  }

  Future<InventoryItemRow?> _select(String playerLocalId, InventoryKind kind) {
    return (_db.select(_db.inventoryItems)..where(
          (i) =>
              i.playerLocalId.equals(playerLocalId) &
              i.itemId.equals(kind.name),
        ))
        .getSingleOrNull();
  }

  Future<void> _write(String playerLocalId, InventoryKind kind, int quantity) {
    return _db
        .into(_db.inventoryItems)
        .insertOnConflictUpdate(
          InventoryItemsCompanion.insert(
            playerLocalId: playerLocalId,
            itemId: kind.name,
            quantity: Value(quantity),
            updatedAt: _now().millisecondsSinceEpoch,
          ),
        );
  }

  static Map<InventoryKind, int> _toMap(List<InventoryItemRow> rows) {
    return {
      for (final row in rows)
        for (final kind in InventoryKind.values)
          if (kind.name == row.itemId) kind: row.quantity,
    };
  }
}
