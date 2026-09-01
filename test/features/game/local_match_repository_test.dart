import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/game/model/match_rewards.dart';
import 'package:memory_companion/features/game/repository/local_match_repository.dart';
import 'package:memory_companion/features/level_map/repository/local_level_repository.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository playerRepository;
  late LocalMatchRepository matchRepository;
  late LocalLevelRepository levelRepository;
  late PlayerProfile player;
  late DateTime now;
  late int opCounter;

  setUp(() async {
    opCounter = 0;
    db = AppDatabase.forTesting(NativeDatabase.memory());
    now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    playerRepository = PlayerRepository(
      database: db,
      syncQueue: SyncQueue(database: db),
      idGenerator: () => 'local-1',
      clock: () => now,
    );
    levelRepository = LocalLevelRepository(database: db, clock: () => now);
    matchRepository = LocalMatchRepository(
      database: db,
      playerRepository: playerRepository,
      levelRepository: levelRepository,
      syncQueue: SyncQueue(database: db),
      idGenerator: () => 'op-${++opCounter}',
      clock: () => now,
    );
    player = await playerRepository.ensureLocalProfile();
  });

  tearDown(() async {
    await db.close();
  });

  Future<bool> record(
    String matchId, {
    bool won = true,
    MatchRewards rewards = const MatchRewards(coins: 125, xp: 201),
    int moves = 12,
    int score = 1200,
    DateTime? playedAt,
    int? levelNumber,
  }) {
    return matchRepository.recordMatch(
      matchId: matchId,
      playerLocalId: player.localId,
      gameMode: 'solo',
      score: score,
      moves: moves,
      secondsElapsed: 40,
      timeLimit: 90,
      rewards: rewards,
      won: won,
      playedAt: playedAt,
      levelNumber: levelNumber,
    );
  }

  test('una victoria queda registrada y pagada en la misma operación',
      () async {
    expect(await record('match-1'), isTrue);

    final match = await db.select(db.matches).getSingle();
    expect(match.id, 'match-1');
    expect(match.won, isTrue);
    expect(match.coinsEarned, 125);
    expect(match.syncStatus, SyncStatus.pending, reason: 'espera a subir');

    final profile = await playerRepository.readLocalProfile();
    expect(profile!.totalCoins, 125);
    expect(profile.totalXp, 201);
    expect(profile.totalMoves, 12);
    expect(profile.gamesWon, 1);
  });

  test('registrar la misma partida dos veces no paga dos veces', () async {
    expect(await record('match-1'), isTrue);
    // Esto es un reintento de sincronización cuya respuesta se perdió.
    expect(await record('match-1'), isFalse);

    expect(await db.select(db.matches).get(), hasLength(1));
    final profile = await playerRepository.readLocalProfile();
    expect(profile!.totalCoins, 125, reason: 'sin doble abono');
    expect(profile.totalXp, 201);
    expect(profile.gamesWon, 1);
  });

  test('perder cuenta la partida pero no suma victoria ni monedas', () async {
    await record(
      'match-1',
      won: false,
      rewards: const MatchRewards(coins: 0, xp: 10),
      moves: 30,
    );

    final profile = await playerRepository.readLocalProfile();
    expect(profile!.gamesWon, 0);
    expect(profile.totalCoins, 0);
    expect(profile.totalXp, 10, reason: 'jugar siempre deja algo');
    expect(profile.totalMoves, 30);
    expect(await db.select(db.matches).get(), hasLength(1));
  });

  test('varias partidas acumulan sin pisarse', () async {
    await record('match-1');
    await record('match-2', rewards: const MatchRewards(coins: 60, xp: 130));
    await record(
      'match-3',
      won: false,
      rewards: const MatchRewards(coins: 0, xp: 10),
      moves: 25,
    );

    final profile = await playerRepository.readLocalProfile();
    expect(profile!.totalCoins, 185);
    expect(profile.totalXp, 341);
    expect(profile.gamesWon, 2);
    expect(profile.totalMoves, 49);
  });

  test('watchLastMatch devuelve la más reciente, no la última escrita',
      () async {
    await record(
      'vieja',
      playedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      score: 100,
    );
    await record(
      'reciente',
      playedAt: DateTime.fromMillisecondsSinceEpoch(9000),
      score: 999,
    );
    // Escrita al final, pero jugada en medio.
    await record(
      'intermedia',
      playedAt: DateTime.fromMillisecondsSinceEpoch(5000),
      score: 500,
    );

    final last = await matchRepository.watchLastMatch(player.localId).first;
    expect(last, isNotNull);
    expect(last!.id, 'reciente');
    expect(last.score, 999);
  });

  test('sin partidas, la última es null', () async {
    expect(await matchRepository.watchLastMatch(player.localId).first, isNull);
  });

  test('ganar un nivel lo completa en la misma operación', () async {
    await record('match-1', levelNumber: 1, score: 1200);

    final levels = await levelRepository.watchLevels(player.localId).first;
    expect(levels[0].isCompleted, isTrue);
    expect(levels[0].bestScore, 1200);
    expect(levels[1].isUnlocked, isTrue, reason: 'el siguiente se abre');
    expect(await levelRepository.currentLevelNumber(player.localId), 2);
  });

  test('perder un nivel no lo completa', () async {
    await record(
      'match-1',
      won: false,
      rewards: const MatchRewards(coins: 0, xp: 10),
      levelNumber: 1,
    );

    final levels = await levelRepository.watchLevels(player.localId).first;
    expect(levels[0].isCompleted, isFalse);
    expect(levels[1].isUnlocked, isFalse);
  });

  test('el historial llega ordenado de más nueva a más vieja', () async {
    await record('a', playedAt: DateTime.fromMillisecondsSinceEpoch(1000));
    await record('b', playedAt: DateTime.fromMillisecondsSinceEpoch(3000));
    await record('c', playedAt: DateTime.fromMillisecondsSinceEpoch(2000));

    final history =
        await matchRepository.watchRecentMatches(player.localId).first;
    expect(history.map((m) => m.id), ['b', 'c', 'a']);
  });
}
