import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/level_map/repository/local_level_repository.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

void main() {
  late AppDatabase db;
  late LocalLevelRepository repository;
  late String playerId;
  late DateTime now;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    now = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    repository = LocalLevelRepository(database: db, clock: () => now);

    final player = await PlayerRepository(
      database: db,
      syncQueue: SyncQueue(database: db),
      idGenerator: () => 'local-1',
      clock: () => now,
    ).ensureLocalProfile();
    playerId = player.localId;
  });

  tearDown(() async {
    await db.close();
  });

  test('un jugador nuevo tiene los 50 niveles y solo el primero abierto',
      () async {
    final levels = await repository.watchLevels(playerId).first;

    expect(levels, hasLength(kTotalLevels));
    expect(levels.first.levelNumber, 1);
    expect(levels.first.isUnlocked, isTrue);
    expect(levels.first.isCompleted, isFalse);
    expect(levels[1].isUnlocked, isFalse);
    expect(await repository.currentLevelNumber(playerId), 1);
  });

  test('la definición del nivel no se guarda: se genera', () async {
    final levels = await repository.watchLevels(playerId).first;

    // Progresión determinista: nada de esto viaja ni ocupa una fila.
    expect(levels[0].timeLimit, 90);
    expect(levels[0].cardsCount, 16);
    expect(levels[5].timeLimit, 80, reason: 'baja 10s cada 5 niveles');
    expect(levels.last.timeLimit, greaterThanOrEqualTo(30));

    // Y la tabla sigue vacía: solo se escribe el progreso real.
    expect(await db.select(db.levelProgress).get(), isEmpty);
  });

  test('completar un nivel abre el siguiente', () async {
    await repository.completeLevel(
      playerLocalId: playerId,
      levelNumber: 1,
      score: 800,
    );

    final levels = await repository.watchLevels(playerId).first;
    expect(levels[0].isCompleted, isTrue);
    expect(levels[0].bestScore, 800);
    expect(levels[1].isUnlocked, isTrue);
    expect(levels[1].isCompleted, isFalse);
    expect(levels[2].isUnlocked, isFalse);
    expect(await repository.currentLevelNumber(playerId), 2);
  });

  test('la mejor marca se resuelve con máximo, no con el último', () async {
    Future<void> play(int score) => repository.completeLevel(
          playerLocalId: playerId,
          levelNumber: 1,
          score: score,
        );

    await play(1500);
    await play(600); // una partida peor no debe borrar el récord

    final levels = await repository.watchLevels(playerId).first;
    expect(levels[0].bestScore, 1500);
  });

  test('repetir un nivel no reescribe cuándo se completó', () async {
    await repository.completeLevel(
      playerLocalId: playerId,
      levelNumber: 1,
      score: 800,
    );
    final firstCompletion = (await db.select(db.levelProgress).getSingle())
        .completedAt;

    now = now.add(const Duration(days: 3));
    await repository.completeLevel(
      playerLocalId: playerId,
      levelNumber: 1,
      score: 900,
    );

    final row = await db.select(db.levelProgress).getSingle();
    expect(row.completedAt, firstCompletion);
    expect(row.bestScore, 900);
  });

  test('el nivel actual es el primero sin completar, no el más alto', () async {
    // Completar el 1 y el 3 sin el 2 no debe dejar un hueco abierto.
    await repository.completeLevel(
      playerLocalId: playerId,
      levelNumber: 1,
      score: 100,
    );
    await repository.completeLevel(
      playerLocalId: playerId,
      levelNumber: 3,
      score: 100,
    );

    expect(await repository.currentLevelNumber(playerId), 2);
  });

  test('un número de nivel fuera de rango se ignora', () async {
    await repository.completeLevel(
      playerLocalId: playerId,
      levelNumber: 0,
      score: 100,
    );
    await repository.completeLevel(
      playerLocalId: playerId,
      levelNumber: kTotalLevels + 1,
      score: 100,
    );

    expect(await db.select(db.levelProgress).get(), isEmpty);
  });

  test('completar en cadena avanza el progreso', () async {
    for (var level = 1; level <= 5; level++) {
      await repository.completeLevel(
        playerLocalId: playerId,
        levelNumber: level,
        score: level * 100,
      );
    }

    final levels = await repository.watchLevels(playerId).first;
    expect(levels.take(5).every((l) => l.isCompleted), isTrue);
    expect(levels[5].isUnlocked, isTrue);
    expect(await repository.currentLevelNumber(playerId), 6);
    // Cinco filas para cinco niveles jugados, no cincuenta.
    expect(await db.select(db.levelProgress).get(), hasLength(5));
  });
}
