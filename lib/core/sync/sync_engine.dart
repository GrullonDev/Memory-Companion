import 'package:memory_companion/core/sync/sync_gateway.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';

/// Resultado de una pasada del motor.
class SyncRunResult {
  const SyncRunResult({
    this.applied = 0,
    this.failed = 0,
    this.skippedReason,
  });

  /// No se intentó nada, y por qué.
  const SyncRunResult.skipped(String reason) : this(skippedReason: reason);

  final int applied;
  final int failed;
  final String? skippedReason;

  bool get didWork => applied > 0;
  bool get wasSkipped => skippedReason != null;

  @override
  String toString() => wasSkipped
      ? 'SyncRunResult(omitido: $skippedReason)'
      : 'SyncRunResult(aplicadas: $applied, fallidas: $failed)';
}

/// El motor de sincronización.
///
/// Procesa la cola **en serie y en orden de creación**: subir la partida
/// antes que el nivel que desbloqueó mantiene la nube en estados que siempre
/// tuvieron sentido.
///
/// Un jugador sin cuenta no es un caso de error: sus operaciones se quedan
/// esperando indefinidamente, y esa cola es exactamente su backlog para el
/// día que decida registrarse.
class SyncEngine {
  SyncEngine({
    required SyncQueue queue,
    required SyncGateway gateway,
    DateTime Function()? clock,
    Duration Function(int attempt)? backoff,
  })  : _queue = queue,
        _gateway = gateway,
        _now = clock ?? DateTime.now,
        _backoff = backoff ?? defaultBackoff;

  /// Espera entre reintentos. Ocho intentos cubren algo más de una hora.
  ///
  /// Sin jitter a propósito: el jitter existe para que mil clientes no
  /// golpeen a la vez tras una caída, y aquí cada dispositivo tiene su propia
  /// cola. Añadirlo solo haría los tests no deterministas.
  static Duration defaultBackoff(int attempt) {
    const delays = <Duration>[
      Duration(seconds: 2),
      Duration(seconds: 8),
      Duration(seconds: 30),
      Duration(minutes: 2),
      Duration(minutes: 10),
      Duration(hours: 1),
    ];
    final index = attempt - 1;
    if (index < 0) return delays.first;
    return index >= delays.length ? delays.last : delays[index];
  }

  final SyncQueue _queue;
  final SyncGateway _gateway;
  final DateTime Function() _now;
  final Duration Function(int attempt) _backoff;

  /// Una pasada completa.
  ///
  /// [cloudUid] nulo significa jugador sin cuenta: se omite sin tocar la cola.
  Future<SyncRunResult> run({
    required String playerLocalId,
    required String? cloudUid,
    int limit = 25,
  }) async {
    if (cloudUid == null) {
      return const SyncRunResult.skipped('sin cuenta');
    }

    // Lo que quedó a medias por una muerte de la app vuelve a la cola. Como
    // la subida es idempotente, reintentarlo no puede duplicar nada.
    await _queue.rescueStuck(playerLocalId: playerLocalId);

    final operations = await _queue.takeEligible(
      playerLocalId: playerLocalId,
      now: _now(),
      limit: limit,
    );
    if (operations.isEmpty) {
      return const SyncRunResult.skipped('nada pendiente');
    }

    var applied = 0;
    var failed = 0;

    for (final operation in operations) {
      await _queue.markSyncing(operation.opId);

      try {
        await _gateway.apply(operation, cloudUid: cloudUid);
        await _queue.markSynced(operation.opId);
        applied++;
      } on SyncFailure catch (failure) {
        failed++;
        await _recordFailure(operation.opId, operation.retryCount,
            failure.message, permanent: failure.permanent);

        // Un fallo transitorio casi siempre es la red: seguir martillando las
        // 24 operaciones restantes solo gasta batería y las condena a todas.
        if (!failure.permanent) break;
      } catch (error) {
        failed++;
        await _recordFailure(
          operation.opId,
          operation.retryCount,
          error.toString(),
          permanent: false,
        );
        break;
      }
    }

    return SyncRunResult(applied: applied, failed: failed);
  }

  /// Devuelve a la cola lo que se había dado por perdido.
  ///
  /// Se llama cuando vuelve la conexión: un fallo por red no debe condenar
  /// una operación para siempre.
  Future<void> retryFailed(String playerLocalId) {
    return _queue.retryFailed(playerLocalId: playerLocalId, now: _now());
  }

  Future<void> _recordFailure(
    String opId,
    int retryCount,
    String message, {
    required bool permanent,
  }) {
    return _queue.markFailed(
      opId,
      error: message,
      nextAttemptAt: _now().add(_backoff(retryCount + 1)),
      permanent: permanent,
    );
  }
}
