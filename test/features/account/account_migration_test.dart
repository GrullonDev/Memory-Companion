import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/account/repository/account_migration.dart';
import 'package:memory_companion/features/game/model/match_rewards.dart';
import 'package:memory_companion/features/game/repository/local_match_repository.dart';
import 'package:memory_companion/features/level_map/repository/local_level_repository.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

/// La promesa que estos tests defienden: **un jugador que lleva un mes sin
/// cuenta no pierde nada al crearla.**
void main() {
  late AppDatabase db;
  late SyncQueue queue;
  late PlayerRepository players;
  late LocalMatchRepository matches;
  late AccountMigration migration;
  late String playerId;
  late DateTime now;
  var ids = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    queue = SyncQueue(database: db);
    now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    ids = 0;

    players = PlayerRepository(
      database: db,
      syncQueue: queue,
      idGenerator: () => 'op-${++ids}',
      clock: () => now,
    );
    matches = LocalMatchRepository(
      database: db,
      playerRepository: players,
      levelRepository: LocalLevelRepository(database: db, clock: () => now),
      syncQueue: queue,
      idGenerator: () => 'op-${++ids}',
      clock: () => now,
    );
    migration = AccountMigration(
      database: db,
      syncQueue: queue,
      clock: () => now,
    );

    playerId = (await players.ensureLocalProfile()).localId;
  });

  tearDown(() async {
    await db.close();
  });

  /// Un mes de juego sin cuenta.
  Future<void> playForAMonth() async {
    for (var day = 1; day <= 3; day++) {
      await matches.recordMatch(
        matchId: 'match-$day',
        playerLocalId: playerId,
        gameMode: 'solo',
        score: 1200,
        moves: 12,
        secondsElapsed: 40,
        timeLimit: 90,
        rewards: const MatchRewards(coins: 125, xp: 201),
        won: true,
        levelNumber: day,
      );
      now = now.add(const Duration(days: 1));
    }
    await players.updateIdentity(localId: playerId, displayName: 'Jorge');
  }

  test('la adopción encola todo el progreso, sin borrar nada', () async {
    await playForAMonth();
    final before = await players.readLocalProfile();

    final enqueued = await migration.enqueueFullState(playerId);

    expect(enqueued, greaterThan(0));

    final operations = await (db.select(db.syncOperations)
          ..where((o) => o.opId.like('migration:%')))
        .get();
    final types = operations.map((o) => o.type).toSet();

    expect(types, contains(SyncOperationType.upsertProfile));
    expect(types, contains(SyncOperationType.updateStreak));
    expect(types, contains(SyncOperationType.addXp));
    expect(types, contains(SyncOperationType.earnCoins));
    expect(
      operations.where((o) => o.type == SyncOperationType.createMatch),
      hasLength(3),
      reason: 'una operación por partida jugada',
    );
    expect(
      operations.where((o) => o.type == SyncOperationType.completeLevel),
      hasLength(3),
    );

    // Nada local se toca: la base sigue siendo la fuente de verdad.
    final after = await players.readLocalProfile();
    expect(after!.totalXp, before!.totalXp);
    expect(after.totalCoins, before.totalCoins);
    expect(await db.select(db.matches).get(), hasLength(3));
  });

  test('los totales viajan como deltas, no como totales', () async {
    await playForAMonth();
    final profile = await players.readLocalProfile();

    await migration.enqueueFullState(playerId);

    final xpOp = await (db.select(db.syncOperations)
          ..where((o) => o.type.equalsValue(SyncOperationType.addXp))
          ..where((o) => o.opId.like('migration:%')))
        .getSingle();

    // Sumar sobre un documento vacío da el total: es correcto precisamente
    // porque la adopción solo ocurre cuando la nube está a cero.
    expect(xpOp.payloadJson, contains('${profile!.totalXp}'));
  });

  test('reanudar una migración a medias no duplica nada', () async {
    await playForAMonth();

    await migration.enqueueFullState(playerId);
    final first = await db.select(db.syncOperations).get();

    // La app murió a mitad de la migración y al volver se reintenta. Con
    // identificadores deterministas esto es un no-op: sin ellos, el servidor
    // aplicaría el XP y las monedas acumuladas **dos veces**.
    await migration.enqueueFullState(playerId);
    final second = await db.select(db.syncOperations).get();

    expect(second, hasLength(first.length), reason: 'mismos opId, sin duplicar');
    expect(
      second.map((o) => o.opId).toSet(),
      first.map((o) => o.opId).toSet(),
    );
  });

  test('quedarse con el progreso de la cuenta sustituye el local', () async {
    await playForAMonth();

    await migration.adoptCloudProfile(
      playerLocalId: playerId,
      cloudProfile: const {
        'displayName': 'JorgeNube',
        'totalXp': 99000,
        'totalCoins': 4300,
        'gamesWon': 120,
        'totalMoves': 900,
        'currentStreak': 12,
        'longestStreak': 30,
        'lastPlayedDate': '2026-08-20',
      },
    );

    final profile = await players.readLocalProfile();
    expect(profile!.displayName, 'JorgeNube');
    expect(profile.totalXp, 99000);
    expect(profile.totalCoins, 4300);
    expect(profile.longestStreak, 30);

    // La cola pendiente describía un progreso que el jugador acaba de decidir
    // no conservar: subirla lo mezclaría con lo que pidió mantener.
    expect(await queue.pendingCount(playerId), 0);
  });

  test('quedarse con la nube no borra el historial local de partidas',
      () async {
    await playForAMonth();

    await migration.adoptCloudProfile(
      playerLocalId: playerId,
      cloudProfile: const {'totalXp': 99000},
    );

    // Las partidas jugadas ocurrieron: no se reescribe la historia.
    expect(await db.select(db.matches).get(), hasLength(3));
  });

  test('un perfil sin progreso encola lo mínimo', () async {
    final enqueued = await migration.enqueueFullState(playerId);

    // Identidad y racha siempre; nada de acumulados ni partidas.
    expect(enqueued, 2);
  });

  test('un jugador desconocido no encola nada', () async {
    expect(await migration.enqueueFullState('no-existe'), 0);
  });
}
