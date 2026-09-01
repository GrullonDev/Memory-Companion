import 'dart:convert';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';

/// Una operación pendiente de subir a la nube.
///
/// La cola guarda **deltas, nunca totales**: «suma 201 XP», no «el XP ahora
/// es 8.601». Es lo que permite que dos dispositivos que jugaron sin conexión
/// converjan sumando en lugar de pisarse.
///
/// [opId] es además el identificador del documento en
/// `users/{uid}/sync_ops/{opId}`. Escribir ese registro dentro de la misma
/// transacción que el efecto es lo que hace la operación idempotente: si la
/// respuesta se pierde y reintentamos, la transacción encuentra el registro y
/// no vuelve a aplicar nada.
class SyncOperation {
  const SyncOperation({
    required this.opId,
    required this.playerLocalId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.status,
    required this.retryCount,
    required this.nextAttemptAt,
    this.lastError,
  });

  factory SyncOperation.fromRow(SyncOperationRow row) {
    return SyncOperation(
      opId: row.opId,
      playerLocalId: row.playerLocalId,
      type: row.type,
      entityType: row.entityType,
      entityId: row.entityId,
      payload: _decodePayload(row.payloadJson),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      status: row.status,
      retryCount: row.retryCount,
      nextAttemptAt: DateTime.fromMillisecondsSinceEpoch(row.nextAttemptAt),
      lastError: row.lastError,
    );
  }

  static Map<String, Object?> _decodePayload(String raw) {
    if (raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, Object?> ? decoded : const {};
  }

  final String opId;
  final String playerLocalId;
  final SyncOperationType type;
  final String entityType;
  final String entityId;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final SyncStatus status;
  final int retryCount;
  final DateTime nextAttemptAt;
  final String? lastError;

  /// Lee un entero del payload sin reventar si falta o viene mal.
  int intValue(String key, {int fallback = 0}) {
    final value = payload[key];
    return value is int ? value : fallback;
  }

  Map<String, Object?> mapValue(String key) {
    final value = payload[key];
    return value is Map<String, Object?> ? value : const {};
  }

  @override
  String toString() => 'SyncOperation(${type.name}, $opId, $status)';
}

/// Lo que hace falta para encolar. El estado, los reintentos y el backoff los
/// pone la propia cola.
class SyncOperationInput {
  const SyncOperationInput({
    required this.opId,
    required this.playerLocalId,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.payload,
  });

  final String opId;
  final String playerLocalId;
  final SyncOperationType type;
  final String entityType;
  final String entityId;
  final Map<String, Object?> payload;

  String get payloadJson => jsonEncode(payload);
}
