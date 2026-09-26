import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/ladder/ladder_reward_repository.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

void main() {
  late AppDatabase db;
  late PlayerRepository players;
  late LadderRewardRepository rewards;
  late String playerId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    players = PlayerRepository(
      database: db,
      syncQueue: SyncQueue(database: db),
    );
    rewards = LadderRewardRepository(database: db, playerRepository: players);
    playerId = (await players.ensureLocalProfile()).localId;
  });

  tearDown(() => db.close());

  Future<int> coins() async => (await players.readLocalProfile())!.totalCoins;

  Future<List<int>> claim(String ladderId, int level) async => [
    for (final reward in await rewards.claim(
      ladderId: ladderId,
      level: level,
      playerLocalId: playerId,
    ))
      reward.level,
  ];

  test('antes del primer peldaño no hay nada que cobrar', () async {
    expect(await claim('classic', 1), isEmpty);
    expect(await claim('classic', 5), isEmpty);
    expect(await coins(), 0);
  });

  test('completar el nivel 5 paga su regalo una sola vez', () async {
    // Nivel 6 = el 5 está completado.
    expect(await claim('classic', 6), [5]);
    expect(await claim('classic', 6), isEmpty);
    expect(await coins(), 100);
  });

  test('quien ya iba por el nivel 7 recupera el premio del 5', () async {
    expect(await claim('classic', 7), [5]);
    expect(await coins(), 100);
  });

  test('un nivel viejo no paga ni deshace lo cobrado', () async {
    await claim('classic', 11);
    expect(await claim('classic', 3), isEmpty);
    expect(await claim('classic', 11), isEmpty);
    // Regalo del 5 (100) y cofre del 10 (400).
    expect(await coins(), 500);
  });

  test('cada juego lleva su propia escalera', () async {
    expect(await claim('classic', 6), [5]);
    expect(await claim('numeric', 3), isEmpty);
    expect(await claim('game:crossword', 6), [5]);
    expect(await coins(), 200);
  });
}
