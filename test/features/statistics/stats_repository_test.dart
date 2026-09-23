import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';

/// Deja correr el bucle de eventos hasta que [done] se cumpla.
Future<void> pumpEventQueueUntil(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AppDatabase db;
  late StatsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = StatsRepository(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  GameStats game({
    required DateTime date,
    int pairs = 6,
    int matched = 6,
    int moves = 8,
    int errors = 1,
    int seconds = 60,
    bool won = true,
  }) {
    return GameStats(
      date: date,
      categoryId: 'classic',
      pairCount: pairs,
      matchedPairs: matched,
      moves: moves,
      memoryErrors: errors,
      hintsUsed: 0,
      timeSeconds: seconds,
      timeLimitSeconds: 90,
      timed: true,
      won: won,
      score: 1000,
    );
  }

  test('sin partidas el resumen está vacío', () async {
    final snapshot = await repository.readSnapshot(sinceDay: '2000-01-01');

    expect(snapshot.totals.isEmpty, isTrue);
    expect(snapshot.totals.accuracy, isNull);
    expect(snapshot.record, isNull);
    expect(snapshot.daily, isEmpty);
    expect(snapshot.playedDays, isEmpty);
  });

  test('los totales suman en SQL, y el tiempo solo cuenta victorias', () async {
    await repository.record(game(date: DateTime(2026, 9, 20, 10)));
    await repository.record(
      game(date: DateTime(2026, 9, 21, 10), moves: 12, errors: 3, seconds: 90),
    );
    await repository.record(
      game(
        date: DateTime(2026, 9, 21, 11),
        matched: 2,
        moves: 10,
        seconds: 90,
        won: false,
      ),
    );

    final totals = (await repository.readSnapshot(
      sinceDay: '2026-09-01',
    )).totals;
    expect(totals.games, 3);
    expect(totals.wins, 2);
    expect(totals.matchedPairs, 14);
    expect(totals.moves, 30);
    expect(totals.memoryErrors, 5);
    expect(totals.wonSeconds, 150);
    expect(totals.wonPairs, 12);
    expect(totals.accuracy, closeTo(14 / 30, 1e-9));
  });

  test(
    'el récord es el mejor tiempo por pareja, no el tablero más pequeño',
    () async {
      await repository.record(
        game(date: DateTime(2026, 9, 20), pairs: 3, matched: 3, seconds: 30),
      );
      await repository.record(
        game(date: DateTime(2026, 9, 21), pairs: 12, matched: 12, seconds: 96),
      );
      await repository.record(
        game(date: DateTime(2026, 9, 22), pairs: 12, seconds: 20, won: false),
      );

      final snapshot = await repository.readSnapshot(sinceDay: '2026-09-01');
      expect(snapshot.record, (seconds: 96, pairCount: 12));
    },
  );

  test('agrupa por día local y respeta la ventana pedida', () async {
    await repository.record(game(date: DateTime(2026, 8, 1, 9)));
    await repository.record(game(date: DateTime(2026, 9, 21, 9)));
    await repository.record(game(date: DateTime(2026, 9, 21, 23, 59)));
    await repository.record(game(date: DateTime(2026, 9, 22, 0, 1)));

    final snapshot = await repository.readSnapshot(sinceDay: '2026-09-01');
    expect(
      [for (final d in snapshot.daily) d.day],
      ['2026-09-21', '2026-09-22'],
    );
    expect(snapshot.daily.first.stats.games, 2);
    expect(snapshot.playedDays, ['2026-09-22', '2026-09-21', '2026-08-01']);
  });

  test(
    'el historial se pagina por cursor, del más reciente al más antiguo',
    () async {
      for (var i = 0; i < 45; i++) {
        await repository.record(
          game(date: DateTime(2026, 9, 1).add(Duration(hours: i))),
        );
      }

      final first = await repository.recentGames(limit: 20);
      final second = await repository.recentGames(
        limit: 20,
        beforeId: first.last.id,
      );
      final third = await repository.recentGames(
        limit: 20,
        beforeId: second.last.id,
      );

      expect(first, hasLength(20));
      expect(second, hasLength(20));
      expect(third, hasLength(5));
      final ids = [...first, ...second, ...third].map((g) => g.id).toList();
      expect(ids.toSet(), hasLength(45), reason: 'sin repetidos');
      expect(
        first.first.date,
        DateTime(2026, 9, 1).add(const Duration(hours: 44)),
      );
    },
  );

  test('watchSnapshot emite de nuevo tras cada partida', () async {
    final emitted = <int>[];
    final subscription = repository
        .watchSnapshot(sinceDay: '2026-01-01')
        .listen((s) => emitted.add(s.totals.games));

    await pumpEventQueueUntil(() => emitted.isNotEmpty);
    await repository.record(game(date: DateTime(2026, 9, 23)));
    await pumpEventQueueUntil(() => emitted.length == 2);
    await subscription.cancel();

    expect(emitted, [0, 1]);
  });

  test('ida y vuelta por JSON conserva la partida', () {
    final original = game(date: DateTime(2026, 9, 23, 8, 15));
    final copy = GameStats.fromJson(original.toJson());

    expect(copy.toJson(), original.toJson());
    expect(copy.accuracy, 0.75);
  });
}
