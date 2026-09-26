import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/database/tables/player_profiles.dart';

/// La cola de sincronización: el corazón del motor.
///
/// [opId] es un UUID que además será el ID del documento en
/// `users/{uid}/sync_ops/{opId}`. Escribir ese documento *dentro de la misma
/// transacción* que el efecto es lo que hace idempotente la operación: si la
/// respuesta se pierde y reintentamos, la transacción encuentra el registro y
/// no vuelve a aplicar nada.
///
/// Para un jugador sin cuenta la cola simplemente se acumula: es su backlog
/// para el día que decida registrarse.
@DataClassName('SyncOperationRow')
@TableIndex(
  name: 'idx_sync_ops_status_next_attempt',
  columns: {#status, #nextAttemptAt},
)
@TableIndex(name: 'idx_sync_ops_player_created', columns: {#playerLocalId, #createdAt})
class SyncOperations extends Table {
  TextColumn get opId => text()();
  TextColumn get playerLocalId =>
      text().references(PlayerProfiles, #localId)();

  TextColumn get type => textEnum<SyncOperationType>()();

  /// Qué se toca (`player`, `match`, `level`, `challenge`) y cuál.
  /// Permite descartar operaciones obsoletas sin interpretar el payload.
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();

  /// Los deltas de la operación, serializados. Nunca totales.
  TextColumn get payloadJson => text()();

  IntColumn get createdAt => integer()();
  TextColumn get status => textEnum<SyncStatus>()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Momento a partir del cual esta operación vuelve a ser elegible.
  /// Es el backoff exponencial, expresado como dato en vez de como espera.
  IntColumn get nextAttemptAt => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {opId};
}
