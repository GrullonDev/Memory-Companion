import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_operation.dart';

/// La cola de operaciones pendientes de subir.
///
/// Es un DAO sobre `sync_operations`. Al compartir la misma [AppDatabase] que
/// los repositorios, encolar **dentro** de la transacción que hace el cambio
/// local participa de esa misma transacción: o se guardan el efecto y su
/// operación, o no se guarda ninguno de los dos. Nunca puede quedar progreso
/// local sin su orden de subida.
class SyncQueue {
  SyncQueue({required AppDatabase database}) : _db = database;

  /// Número máximo de intentos antes de rendirse hasta el siguiente evento
  /// de conectividad. Ocho intentos con backoff cubren más de una hora.
  static const int maxRetries = 8;

  final AppDatabase _db;

  Future<void> enqueue(SyncOperationInput input, {required DateTime now}) {
    return _db.into(_db.syncOperations).insert(
          SyncOperationsCompanion.insert(
            opId: input.opId,
            playerLocalId: input.playerLocalId,
            type: input.type,
            entityType: input.entityType,
            entityId: input.entityId,
            payloadJson: input.payloadJson,
            createdAt: now.millisecondsSinceEpoch,
            status: SyncStatus.pending,
          ),
          // Reencolar la misma operación no la duplica.
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Operaciones listas para intentarse, en orden de creación.
  ///
  /// El orden importa: subir la partida antes que el nivel que desbloqueó
  /// mantiene la nube en estados que siempre tuvieron sentido.
  Future<List<SyncOperation>> takeEligible({
    required String playerLocalId,
    required DateTime now,
    int limit = 25,
  }) async {
    final rows = await (_db.select(_db.syncOperations)
          ..where((o) => o.playerLocalId.equals(playerLocalId))
          ..where((o) => o.status.equalsValue(SyncStatus.pending))
          ..where(
            (o) => o.nextAttemptAt.isSmallerOrEqualValue(
              now.millisecondsSinceEpoch,
            ),
          )
          ..orderBy([(o) => OrderingTerm.asc(o.createdAt)])
          ..limit(limit))
        .get();

    return [for (final row in rows) SyncOperation.fromRow(row)];
  }

  Future<void> markSyncing(String opId) => _setStatus(opId, SyncStatus.syncing);

  Future<void> markSynced(String opId) => _setStatus(opId, SyncStatus.synced);

  /// Registra un fallo y programa el siguiente intento.
  ///
  /// Un fallo [permanent] —permisos, datos inválidos— no se reintenta:
  /// insistir solo quema cuota y no arregla nada.
  Future<void> markFailed(
    String opId, {
    required String error,
    required DateTime nextAttemptAt,
    required bool permanent,
  }) async {
    final row = await (_db.select(_db.syncOperations)
          ..where((o) => o.opId.equals(opId)))
        .getSingleOrNull();
    if (row == null) return;

    final retries = row.retryCount + 1;
    final exhausted = permanent || retries >= maxRetries;

    await (_db.update(_db.syncOperations)..where((o) => o.opId.equals(opId)))
        .write(
      SyncOperationsCompanion(
        status: Value(exhausted ? SyncStatus.failed : SyncStatus.pending),
        retryCount: Value(retries),
        nextAttemptAt: Value(nextAttemptAt.millisecondsSinceEpoch),
        lastError: Value(error),
      ),
    );
  }

  /// Devuelve a la cola lo que quedó a medias.
  ///
  /// Si la app muere mientras sube una operación, esa fila se queda en
  /// `syncing` para siempre y bloquea el progreso. Al arrancar el motor se
  /// rescatan: como la subida es idempotente, reintentarlas no hace daño.
  Future<int> rescueStuck({required String playerLocalId}) async {
    return (_db.update(_db.syncOperations)
          ..where((o) => o.playerLocalId.equals(playerLocalId))
          ..where((o) => o.status.equalsValue(SyncStatus.syncing)))
        .write(const SyncOperationsCompanion(status: Value(SyncStatus.pending)));
  }

  /// Reabre las operaciones agotadas para un intento más.
  ///
  /// Lo llama el motor cuando vuelve la conexión: un fallo por red no debe
  /// condenar la operación para siempre.
  Future<int> retryFailed({
    required String playerLocalId,
    required DateTime now,
  }) async {
    return (_db.update(_db.syncOperations)
          ..where((o) => o.playerLocalId.equals(playerLocalId))
          ..where((o) => o.status.equalsValue(SyncStatus.failed)))
        .write(
      SyncOperationsCompanion(
        status: const Value(SyncStatus.pending),
        retryCount: const Value(0),
        nextAttemptAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Stream<int> watchPendingCount(String playerLocalId) {
    final count = _db.syncOperations.opId.count();
    final query = _db.selectOnly(_db.syncOperations)
      ..addColumns([count])
      ..where(_db.syncOperations.playerLocalId.equals(playerLocalId))
      ..where(
        _db.syncOperations.status.equalsValue(SyncStatus.synced).not(),
      );

    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  Future<int> pendingCount(String playerLocalId) {
    return watchPendingCount(playerLocalId).first;
  }

  Future<void> _setStatus(String opId, SyncStatus status) {
    return (_db.update(_db.syncOperations)..where((o) => o.opId.equals(opId)))
        .write(SyncOperationsCompanion(status: Value(status)));
  }
}
