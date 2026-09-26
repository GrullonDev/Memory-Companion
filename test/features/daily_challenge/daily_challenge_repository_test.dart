import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_result.dart';
import 'package:memory_companion/features/daily_challenge/repository/daily_challenge_repository.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

void main() {
  late AppDatabase db;
  late DailyChallengeRepository repository;
  late String playerId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DailyChallengeRepository(database: db);
    playerId = (await PlayerRepository(
      database: db,
      syncQueue: SyncQueue(database: db),
    ).ensureLocalProfile()).localId;
  });

  tearDown(() => db.close());

  DailyResult result(String dateKey, {int moves = 14}) => DailyResult(
    dateKey: dateKey,
    number: 266,
    elapsedSeconds: 42,
    moves: moves,
    hintsUsed: 1,
    score: 2790,
    columns: 4,
    grid: [for (final c in 'ggygggggyggr'.split('')) CardRating.fromCode(c)],
  );

  Future<DailyStatus> status(String today) =>
      repository.watch(playerId: playerId, dateKey: today, number: 266).first;

  test('sin partidas: no completado y racha a cero', () async {
    final s = await status('2026-09-23');
    expect(s.completedToday, isFalse);
    expect(s.streak.current, 0);
  });

  test('guarda el resultado y se puede volver a compartir', () async {
    expect(
      await repository.saveResult(
        playerId: playerId,
        result: result('2026-09-23'),
      ),
      isTrue,
    );

    final today = (await status('2026-09-23')).today!;
    expect(today.moves, 14);
    expect(today.elapsedSeconds, 42);
    expect(today.hintsUsed, 1);
    expect(today.emojiRows, ['🟩🟩🟨🟩', '🟩🟩🟩🟩', '🟨🟩🟩🟥']);
  });

  test('solo cuenta el primer intento del día', () async {
    await repository.saveResult(
      playerId: playerId,
      result: result('2026-09-23'),
    );
    final second = await repository.saveResult(
      playerId: playerId,
      result: result('2026-09-23', moves: 6),
    );

    expect(second, isFalse, reason: 'no debe volver a pagar la recompensa');
    expect((await status('2026-09-23')).today!.moves, 14);
  });

  test('la racha se deriva de los días completados', () async {
    for (final day in ['2026-09-20', '2026-09-21', '2026-09-22']) {
      await repository.saveResult(playerId: playerId, result: result(day));
    }

    // Hoy aún sin jugar: la racha de ayer sigue viva.
    expect((await status('2026-09-23')).streak.current, 3);

    await repository.saveResult(
      playerId: playerId,
      result: result('2026-09-23'),
    );
    final s = await status('2026-09-23');
    expect(s.streak.current, 4);
    expect(s.streak.longest, 4);

    // Saltarse un día la rompe, pero la mejor se recuerda.
    final later = await status('2026-09-25');
    expect(later.streak.current, 0);
    expect(later.streak.longest, 4);
  });
}
