// drift y matcher exportan ambos `isNull`/`isNotNull`. En un test el que
// queremos es el de matcher, así que se ocultan los de drift; de drift solo
// necesitamos `Value` e `InsertMode`.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';

/// Toda la capa local se prueba contra una base en memoria: sin disco, sin
/// Firebase y sin red. Es el motivo principal de elegir Drift.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  PlayerProfilesCompanion buildPlayer(String id) {
    return PlayerProfilesCompanion.insert(
      localId: id,
      createdAt: 1000,
      updatedAt: 1000,
    );
  }

  MatchesCompanion buildMatch(String id, String playerId) {
    return MatchesCompanion.insert(
      id: id,
      playerLocalId: playerId,
      gameMode: 'solo',
      score: 1200,
      moves: 24,
      secondsElapsed: 41,
      timeLimit: 90,
      coinsEarned: 50,
      xpEarned: 120,
      won: true,
      playedAt: 1700000000000,
      syncStatus: SyncStatus.pending,
    );
  }

  test('el esquema arranca en la versión 7 y vacío', () async {
    expect(db.schemaVersion, 7);
    expect(await db.select(db.playerProfiles).get(), isEmpty);
    expect(await db.select(db.syncOperations).get(), isEmpty);
    expect(await db.select(db.displaySettings).get(), isEmpty);
  });

  test('un perfil nuevo empieza con los acumulados a cero', () async {
    await db.into(db.playerProfiles).insert(buildPlayer('local-1'));

    final player = await db.select(db.playerProfiles).getSingle();
    expect(player.localId, 'local-1');
    expect(player.cloudUid, isNull, reason: 'nace sin cuenta');
    expect(player.totalXp, 0);
    expect(player.totalCoins, 0);
    expect(player.currentStreak, 0);
    expect(player.lastPlayedDate, isNull);
  });

  test('guarda una partida y la recupera con su enum intacto', () async {
    await db.into(db.playerProfiles).insert(buildPlayer('local-1'));
    await db.into(db.matches).insert(buildMatch('match-1', 'local-1'));

    final match = await db.select(db.matches).getSingle();
    expect(match.id, 'match-1');
    expect(match.won, isTrue);
    expect(match.syncStatus, SyncStatus.pending);
    expect(match.levelNumber, isNull);
  });

  test('reinsertar la misma partida no la duplica', () async {
    await db.into(db.playerProfiles).insert(buildPlayer('local-1'));
    final match = buildMatch('match-1', 'local-1');

    await db.into(db.matches).insert(match);
    // Es lo que hace un reintento de sincronización: mismo id, misma fila.
    await db.into(db.matches).insert(match, mode: InsertMode.insertOrReplace);

    expect(await db.select(db.matches).get(), hasLength(1));
  });

  test('rechaza una partida de un jugador que no existe', () async {
    await expectLater(
      db.into(db.matches).insert(buildMatch('match-1', 'fantasma')),
      throwsA(isA<Exception>()),
    );
  });

  test('level_progress admite un nivel por jugador, no dos', () async {
    await db.into(db.playerProfiles).insert(buildPlayer('local-1'));

    Future<void> insertLevel(int bestScore) {
      return db
          .into(db.levelProgress)
          .insert(
            LevelProgressCompanion.insert(
              playerLocalId: 'local-1',
              levelNumber: 3,
              syncStatus: SyncStatus.pending,
              bestScore: Value(bestScore),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    await insertLevel(800);
    await insertLevel(1500);

    final rows = await db.select(db.levelProgress).get();
    expect(rows, hasLength(1));
    expect(rows.single.bestScore, 1500);
  });

  test('la cola de sincronización se ordena por elegibilidad', () async {
    await db.into(db.playerProfiles).insert(buildPlayer('local-1'));

    Future<void> enqueue(String opId, SyncStatus status, int nextAttemptAt) {
      return db
          .into(db.syncOperations)
          .insert(
            SyncOperationsCompanion.insert(
              opId: opId,
              playerLocalId: 'local-1',
              type: SyncOperationType.recordMatch,
              entityType: 'match',
              entityId: 'match-1',
              payloadJson: '{"xp":120,"coins":50}',
              createdAt: 1,
              status: status,
              nextAttemptAt: Value(nextAttemptAt),
            ),
          );
    }

    await enqueue('op-lista', SyncStatus.pending, 0);
    await enqueue('op-esperando', SyncStatus.pending, 9999999999999);
    await enqueue('op-hecha', SyncStatus.synced, 0);

    final eligible =
        await (db.select(db.syncOperations)
              ..where((o) => o.status.equalsValue(SyncStatus.pending))
              ..where((o) => o.nextAttemptAt.isSmallerOrEqualValue(1000)))
            .get();

    expect(eligible.map((o) => o.opId), ['op-lista']);
  });

  test('migra de la versión 5 a la 6 sin perder partidas ni ajustes', () async {
    final old = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          // Las dos tablas que toca la versión 6, tal como eran en la 5.
          raw.execute('''
            CREATE TABLE game_stats (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              played_at INTEGER NOT NULL, played_day TEXT NOT NULL,
              category_id TEXT NOT NULL, pair_count INTEGER NOT NULL,
              matched_pairs INTEGER NOT NULL, moves INTEGER NOT NULL,
              memory_errors INTEGER NOT NULL, hints_used INTEGER NOT NULL,
              seconds_elapsed INTEGER NOT NULL,
              time_limit_seconds INTEGER NOT NULL, timed INTEGER NOT NULL,
              won INTEGER NOT NULL, score INTEGER NOT NULL)''');
          raw.execute('''
            CREATE TABLE display_settings (
              id INTEGER NOT NULL PRIMARY KEY,
              visual_profile TEXT NOT NULL DEFAULT 'vibrant',
              timed_matches INTEGER NOT NULL DEFAULT 1,
              updated_at INTEGER NOT NULL)''');
          raw.execute(
            "INSERT INTO game_stats VALUES (1, 1000, '2026-09-01', 'classic', "
            '6, 6, 8, 1, 0, 40, 90, 1, 1, 700)',
          );
          raw.execute(
            "INSERT INTO display_settings VALUES (0, 'accessible', 0, 1000)",
          );
          raw.execute('PRAGMA user_version = 5');
        },
      ),
    );
    addTearDown(old.close);

    final [game] = await old.select(old.gameStats).get();
    expect(game.score, 700);
    expect(game.placeId, isNull);
    expect(game.nearby, isNull);

    final settings = await old.select(old.displaySettings).getSingle();
    expect(settings.timedMatches, isFalse);
    expect(settings.contextLocation, isFalse, reason: 'nace apagado');
    expect(settings.contextNearby, isFalse);

    expect(await old.select(old.places).get(), isEmpty);
    // Y la 7 crea la tabla de premios de la escalera, vacía.
    expect(await old.select(old.ladderRewards).get(), isEmpty);
  });
}
