import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/connectivity/controller/connection_status_controller.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/core/sync/firestore_sync_gateway.dart';
import 'package:memory_companion/core/sync/sync_engine.dart';
import 'package:memory_companion/core/sync/sync_gateway.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

final syncQueueProvider = Provider<SyncQueue>((ref) {
  return SyncQueue(database: ref.watch(appDatabaseProvider));
});

final syncGatewayProvider = Provider<SyncGateway>((ref) {
  return FirestoreSyncGateway();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    queue: ref.watch(syncQueueProvider),
    gateway: ref.watch(syncGatewayProvider),
  );
});

/// Cuántas operaciones quedan sin confirmar.
final pendingOperationsProvider = StreamProvider<int>((ref) async* {
  ref.keepAlive();
  final player = await ref.watch(localPlayerProvider.future);
  yield* ref.watch(syncQueueProvider).watchPendingCount(player.localId);
});

/// Cómo se le cuenta al jugador dónde está su progreso.
///
/// Ningún estado dice «error». Para el jugador su progreso **siempre** está
/// guardado; la única variable es dónde.
enum SaveState {
  /// Sin cuenta, o con cambios esperando: vive en este teléfono.
  savedOnDevice,

  /// Subiendo ahora mismo.
  syncing,

  /// Confirmado en la nube.
  savedInCloud,
}

/// El motor, y su disparo automático.
///
/// Se despierta al recuperar la conexión y al aparecer una cuenta. No hay
/// sondeo: nada se consulta en bucle.
class SyncController extends Notifier<bool> {
  @override
  bool build() {
    // Los disparadores tienen que seguir vivos fuera de la Home: si el
    // controlador se destruye al cambiar de pestaña, recuperar la conexión
    // en la Tienda no despertaría al motor.
    ref.keepAlive();

    ref.listen(connectionStatusControllerProvider, (previous, next) {
      if (next == ConnectionStatus.online &&
          previous != ConnectionStatus.online) {
        unawaited(syncNow(retryFailed: true));
      }
    });

    ref.listen(localPlayerProvider, (previous, next) {
      final hadAccount = previous?.value?.cloudUid != null;
      final hasAccount = next.value?.cloudUid != null;
      if (hasAccount && !hadAccount) unawaited(syncNow(retryFailed: true));
    });

    return false;
  }

  /// Ejecuta una pasada. Nunca lanza: un fallo de red no es un error de la
  /// aplicación, es el estado normal de un producto offline-first.
  Future<SyncRunResult> syncNow({bool retryFailed = false}) async {
    if (state) return const SyncRunResult.skipped('ya en curso');

    final player = ref.read(localPlayerProvider).value;
    if (player == null) return const SyncRunResult.skipped('sin jugador');

    state = true;
    try {
      final engine = ref.read(syncEngineProvider);
      if (retryFailed) await engine.retryFailed(player.localId);
      return await engine.run(
        playerLocalId: player.localId,
        cloudUid: player.cloudUid,
      );
    } catch (error) {
      return SyncRunResult.skipped(error.toString());
    } finally {
      state = false;
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, bool>(
  SyncController.new,
);

final saveStateProvider = Provider<SaveState>((ref) {
  final player = ref.watch(localPlayerProvider).value;
  final pending = ref.watch(pendingOperationsProvider).value ?? 0;
  final isRunning = ref.watch(syncControllerProvider);

  if (player?.cloudUid == null) return SaveState.savedOnDevice;
  if (isRunning && pending > 0) return SaveState.syncing;
  return pending == 0 ? SaveState.savedInCloud : SaveState.savedOnDevice;
});
