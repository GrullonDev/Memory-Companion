import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/model/statistics_overview.dart';
import 'package:memory_companion/features/statistics/model/stats_bucket.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';
import 'package:memory_companion/features/statistics/service/stats_analytics.dart';

void main() {
  const analytics = StatsAnalytics();
  final today = DateTime(2026, 9, 23, 18, 30);

  String daysAgo(int n) =>
      dayKey(DateTime(today.year, today.month, today.day - n));

  group('rachas', () {
    test('sin partidas no hay racha', () {
      expect(analytics.computeStreaks([], today), (current: 0, best: 0));
    });

    test('cuenta días seguidos hasta hoy', () {
      final days = [daysAgo(0), daysAgo(1), daysAgo(2), daysAgo(5)];
      expect(analytics.computeStreaks(days, today), (current: 3, best: 3));
    });

    test('la racha sigue viva si aún no se ha jugado hoy', () {
      final days = [daysAgo(1), daysAgo(2)];
      expect(analytics.computeStreaks(days, today).current, 2);
    });

    test('dos días sin jugar la rompen, pero se recuerda la mejor', () {
      final days = [daysAgo(2), daysAgo(10), daysAgo(11), daysAgo(12)];
      expect(analytics.computeStreaks(days, today), (current: 0, best: 3));
    });

    test('cruzar un cambio de hora no rompe la racha', () {
      // En Europa el horario de verano terminó el 25/10/2026.
      final monday = DateTime(2026, 10, 26, 9);
      final days = ['2026-10-26', '2026-10-25', '2026-10-24'];
      expect(analytics.computeStreaks(days, monday).current, 3);
    });
  });

  group('semanas', () {
    test('agrupa los días en ventanas de siete que terminan hoy', () {
      const game = StatsBucket(games: 1, matchedPairs: 6, moves: 8);
      final weeks = analytics.weeklyBuckets([
        (day: daysAgo(0), stats: game),
        (day: daysAgo(6), stats: game),
        (day: daysAgo(7), stats: game),
        (day: daysAgo(55), stats: game),
        (day: daysAgo(56), stats: game), // fuera de la ventana
      ], today);

      expect(weeks, hasLength(8));
      expect(weeks.last.stats.games, 2);
      expect(weeks[6].stats.games, 1);
      expect(weeks.first.stats.games, 1);
      expect(weeks.first.start, DateTime(2026, 7, 30));
      expect(weeks.last.start, DateTime(2026, 9, 17));
      expect(weeks.where((w) => w.stats.isEmpty), hasLength(5));
    });

    test('la ventana del repositorio empieza en el primer día del gráfico', () {
      expect(analytics.windowStartDay(today), '2026-07-30');
    });
  });

  group('tendencia', () {
    StatsBucket week({
      int games = 3,
      int matched = 18,
      int moves = 24,
      int errors = 3,
      int pairs = 18,
      int wonSeconds = 90,
      int wonPairs = 18,
    }) {
      return StatsBucket(
        games: games,
        wins: games,
        matchedPairs: matched,
        moves: moves,
        memoryErrors: errors,
        pairs: pairs,
        wonSeconds: wonSeconds,
        wonPairs: wonPairs,
      );
    }

    test('más rápido, más preciso y con menos errores es progreso', () {
      final trend = analytics.compareWeeks(
        current: week(moves: 20, errors: 1, wonSeconds: 72),
        previous: week(),
      );

      expect(trend.speed.direction, TrendDirection.improving);
      expect(trend.speed.change, closeTo(0.2, 1e-9));
      expect(trend.accuracy.direction, TrendDirection.improving);
      expect(trend.accuracy.change, closeTo(0.9 - 0.75, 1e-9));
      expect(trend.errors.direction, TrendDirection.improving);
      expect(trend.overall, TrendDirection.improving);
    });

    test(
      'el tiempo se compara por pareja: un tablero mayor no es "más lento"',
      () {
        // El doble de parejas en el doble de tiempo: mismo ritmo.
        final trend = analytics.compareWeeks(
          current: week(wonSeconds: 180, wonPairs: 36, pairs: 36, errors: 6),
          previous: week(),
        );
        expect(trend.speed.direction, TrendDirection.steady);
        expect(trend.errors.direction, TrendDirection.steady);
      },
    );

    test('cambios pequeños no se anuncian', () {
      final trend = analytics.compareWeeks(
        current: week(wonSeconds: 88, matched: 18, moves: 24),
        previous: week(),
      );
      expect(trend.speed.direction, TrendDirection.steady);
      expect(trend.accuracy.direction, TrendDirection.steady);
      expect(trend.overall, TrendDirection.steady);
    });

    test('con una sola partida en una semana no hay tendencia', () {
      final trend = analytics.compareWeeks(
        current: week(games: 1, wonSeconds: 10),
        previous: week(),
      );
      expect(trend.overall, TrendDirection.notEnoughData);
    });

    test('errores que aparecen desde cero empeoran sin porcentaje', () {
      final trend = analytics.compareWeeks(
        current: week(errors: 4),
        previous: week(errors: 0),
      );
      expect(trend.errors.direction, TrendDirection.declining);
      expect(trend.errors.change, isNull);
    });
  });

  test('analyze junta totales, racha y tendencia', () {
    final overview = analytics.analyze(
      StatsSnapshot(
        totals: const StatsBucket(
          games: 4,
          wins: 3,
          matchedPairs: 20,
          moves: 25,
        ),
        record: (seconds: 40, pairCount: 8),
        daily: [
          (day: daysAgo(0), stats: const StatsBucket(games: 2)),
          (day: daysAgo(8), stats: const StatsBucket(games: 2)),
        ],
        playedDays: [daysAgo(0), daysAgo(8)],
      ),
      today,
    );

    expect(overview.isEmpty, isFalse);
    expect(overview.playedToday, isTrue);
    expect(overview.currentStreak, 1);
    expect(overview.totals.accuracy, 0.8);
    expect(overview.weeks.last.stats.games, 2);
    expect(overview.weeks[6].stats.games, 2);
  });
}
