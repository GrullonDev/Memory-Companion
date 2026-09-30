import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/tables/player_profiles.dart';

/// Lo que el jugador ha comprado en la tienda con sus monedas y aún no ha
/// gastado: protectores de racha, pistas…
///
/// Una fila por jugador y artículo. [quantity] nunca baja de 0: comprar y
/// gastar ocurren en transacciones que lo comprueban.
///
/// **Solo local**, como `ladder_rewards`: el gasto en monedas sí viaja a la
/// nube por la cola de sincronización del perfil.
@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  TextColumn get playerLocalId => text().references(PlayerProfiles, #localId)();

  /// `StoreItemId.name`. No renombrar nunca un id ya publicado.
  TextColumn get itemId => text()();

  IntColumn get quantity => integer().withDefault(const Constant(0))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {playerLocalId, itemId};
}
