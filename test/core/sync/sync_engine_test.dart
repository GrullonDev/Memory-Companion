import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_engine.dart';
import 'package:memory_companion/core/sync/sync_gateway.dart';
import 'package:memory_companion/core/sync/sync_operation.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';

/// Pasarela falsa: registra lo que se le aplica y puede fallar a voluntad.
///
/// Es la razón de que [SyncGateway] sea una interfaz. Sin ella, probar
/// reintentos, backoff y orden exigiría Firestore real.
class _FakeGateway implements SyncGateway {
  final List<SyncOperation> applied = <SyncOperation>[];

  /// Cuántas de las próximas llamadas deben fallar.
  int failuresLeft = 0;
  SyncFailure failure = const SyncFailure('sin red');
  Map<String, Object?>? profile;

  @override
  Future<void> apply(SyncOperation operation, {required String cloudUid}) async {
    if (failuresLeft > 0) {
      failuresLeft--;
      throw failure;
    }
    applied.add(operation);
  }

  @override
  Future<Map<String, Object?>?> readProfile(String cloudUid) async => profile;
}

void main() {
  late AppDatabase db;
  late SyncQueue queue;
  late _FakeGateway gateway;
  late SyncEngine engine;
  late DateTime now;
  var opCounter = 0;

  const playerId = 'local-1';
  const cloudUid = 'firebase-uid';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = SyncQueue(database: db);
    gateway = _FakeGateway();
    now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    opCounter = 0;
    engine = SyncEngine(queue: queue, gateway: gateway, clock: () => now);

    await db.into(db.playerProfiles).insert(
          PlayerProfilesCompanion.insert(
            localId: playerId,
            createdAt: 0,
            updatedAt: 0,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<String> enqueue({SyncOperationType? type}) async {
    final opId = 'op-${++opCounter}';
    await queue.enqueue(
      SyncOperationInput(
        opId: opId,
        playerLocalId: playerId,
        type: type ?? SyncOperationType.earnCoins,
        entityType: 'player',
        entityId: playerId,
        payload: {'totalCoins': 10},
      ),
      now: now,
    );
    now = now.add(const Duration(milliseconds: 1));
    return opId;
  }

  Future<SyncOperationRow> rowOf(String opId) {
    return (db.select(db.syncOperations)..where((o) => o.opId.equals(opId)))
        .getSingle();
  }

  test('sin cuenta no se intenta nada y la cola se conserva', () async {
    await enqueue();

    final result = await engine.run(playerLocalId: playerId, cloudUid: null);

    expect(result.wasSkipped, isTrue);
    expect(gateway.applied, isEmpty);
    // La cola es el backlog del jugador para cuando decida registrarse.
    expect(await queue.pendingCount(playerId), 1);
  });

  test('con cuenta se suben todas y quedan confirmadas', () async {
    final first = await enqueue();
    final second = await enqueue();

    final result = await engine.run(
      playerLocalId: playerId,
      cloudUid: cloudUid,
    );

    expect(result.applied, 2);
    expect(result.failed, 0);
    expect((await rowOf(first)).status, SyncStatus.synced);
    expect((await rowOf(second)).status, SyncStatus.synced);
    expect(await queue.pendingCount(playerId), 0);
  });

  test('se aplican en orden de creación', () async {
    await enqueue(type: SyncOperationType.recordMatch);
    await enqueue(type: SyncOperationType.completeLevel);
    await enqueue(type: SyncOperationType.earnCoins);

    await engine.run(playerLocalId: playerId, cloudUid: cloudUid);

    expect(
      gateway.applied.map((o) => o.type),
      [
        SyncOperationType.recordMatch,
        SyncOperationType.completeLevel,
        SyncOperationType.earnCoins,
      ],
      reason: 'subir la partida antes que el nivel que desbloqueó',
    );
  });

  test('lo ya confirmado no se vuelve a subir', () async {
    await enqueue();
    await engine.run(playerLocalId: playerId, cloudUid: cloudUid);
    await engine.run(playerLocalId: playerId, cloudUid: cloudUid);

    expect(gateway.applied, hasLength(1));
  });

  test('un fallo de red detiene la pasada y programa el reintento', () async {
    final first = await enqueue();
    final second = await enqueue();
    gateway.failuresLeft = 1;

    final result = await engine.run(
      playerLocalId: playerId,
      cloudUid: cloudUid,
    );

    expect(result.applied, 0);
    expect(result.failed, 1);
    // Insistir con las demás solo gastaría batería y las condenaría a todas.
    expect(gateway.applied, isEmpty);

    final failed = await rowOf(first);
    expect(failed.status, SyncStatus.pending, reason: 'se reintentará');
    expect(failed.retryCount, 1);
    expect(
      failed.nextAttemptAt,
      now.add(const Duration(seconds: 2)).millisecondsSinceEpoch,
    );
    expect((await rowOf(second)).status, SyncStatus.pending);
  });

  test('una operación en espera de backoff no se toma antes de tiempo',
      () async {
    await enqueue();
    gateway.failuresLeft = 1;
    await engine.run(playerLocalId: playerId, cloudUid: cloudUid);

    // Un segundo después todavía no toca.
    now = now.add(const Duration(seconds: 1));
    expect(
      (await engine.run(playerLocalId: playerId, cloudUid: cloudUid))
          .wasSkipped,
      isTrue,
    );

    // Pasado el backoff, sí.
    now = now.add(const Duration(seconds: 5));
    expect(
      (await engine.run(playerLocalId: playerId, cloudUid: cloudUid)).applied,
      1,
    );
  });

  test('el backoff crece con cada intento', () {
    expect(SyncEngine.defaultBackoff(1), const Duration(seconds: 2));
    expect(SyncEngine.defaultBackoff(2), const Duration(seconds: 8));
    expect(SyncEngine.defaultBackoff(3), const Duration(seconds: 30));
    expect(SyncEngine.defaultBackoff(6), const Duration(hours: 1));
    expect(SyncEngine.defaultBackoff(99), const Duration(hours: 1));
  });

  test('un fallo permanente no se reintenta', () async {
    final opId = await enqueue();
    gateway.failuresLeft = 1;
    gateway.failure = const SyncFailure('permission-denied', permanent: true);

    await engine.run(playerLocalId: playerId, cloudUid: cloudUid);

    final row = await rowOf(opId);
    expect(row.status, SyncStatus.failed);
    expect(row.lastError, contains('permission-denied'));

    // Ni siquiera pasado un día: reintentar no lo arregla.
    now = now.add(const Duration(days: 1));
    expect(
      (await engine.run(playerLocalId: playerId, cloudUid: cloudUid))
          .wasSkipped,
      isTrue,
    );
  });

  test('agotar los reintentos la marca fallida', () async {
    final opId = await enqueue();

    for (var attempt = 1; attempt <= SyncQueue.maxRetries; attempt++) {
      gateway.failuresLeft = 1;
      await engine.run(playerLocalId: playerId, cloudUid: cloudUid);
      now = now.add(const Duration(hours: 2));
    }

    expect((await rowOf(opId)).status, SyncStatus.failed);
  });

  test('volver la conexión reabre lo que se había dado por perdido', () async {
    final opId = await enqueue();
    gateway.failuresLeft = 1;
    gateway.failure = const SyncFailure('permission-denied', permanent: true);
    await engine.run(playerLocalId: playerId, cloudUid: cloudUid);
    expect((await rowOf(opId)).status, SyncStatus.failed);

    gateway.failure = const SyncFailure('sin red');
    await engine.retryFailed(playerId);

    final result = await engine.run(
      playerLocalId: playerId,
      cloudUid: cloudUid,
    );
    expect(result.applied, 1);
  });

  test('lo que quedó a medias por un cierre brusco se rescata', () async {
    final opId = await enqueue();
    // Simula que la app murió con la operación en vuelo.
    await queue.markSyncing(opId);
    expect((await rowOf(opId)).status, SyncStatus.syncing);

    final result = await engine.run(
      playerLocalId: playerId,
      cloudUid: cloudUid,
    );

    expect(result.applied, 1, reason: 'reintentar es seguro: es idempotente');
    expect((await rowOf(opId)).status, SyncStatus.synced);
  });

  test('reencolar la misma operación no la duplica', () async {
    final input = SyncOperationInput(
      opId: 'op-fijo',
      playerLocalId: playerId,
      type: SyncOperationType.addXp,
      entityType: 'player',
      entityId: playerId,
      payload: {'totalXp': 50},
    );
    await queue.enqueue(input, now: now);
    await queue.enqueue(input, now: now);

    expect(await queue.pendingCount(playerId), 1);
  });

  test('el payload sobrevive al viaje por JSON', () async {
    await queue.enqueue(
      SyncOperationInput(
        opId: 'op-payload',
        playerLocalId: playerId,
        type: SyncOperationType.recordMatch,
        entityType: 'match',
        entityId: 'match-1',
        payload: {
          'deltas': {'totalXp': 201, 'totalCoins': 125},
          'streak': {'currentStreak': 5, 'lastPlayedDate': '2026-08-31'},
        },
      ),
      now: now,
    );

    final operations = await queue.takeEligible(
      playerLocalId: playerId,
      now: now,
    );
    final deltas = operations.single.mapValue('deltas');
    expect(deltas['totalXp'], 201);
    expect(operations.single.mapValue('streak')['lastPlayedDate'], '2026-08-31');
  });
}
