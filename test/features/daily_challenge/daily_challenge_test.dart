import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/daily_challenge/model/daily_challenge.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_result.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_seed.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_streak.dart';
import 'package:memory_companion/features/daily_challenge/share/daily_share.dart';
import 'package:memory_companion/features/game/board/category/board_factory.dart';

void main() {
  group('DailySeed', () {
    test('la clave es la fecha local con ceros a la izquierda', () {
      expect(DailySeed.dateKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
    });

    test('la semilla está fijada para siempre', () {
      // Si esto cambia, cambian todos los tableros pasados y futuros y los
      // resultados compartidos dejan de corresponder. No actualizar a la
      // ligera.
      expect(DailySeed.seedFor('2026-09-23'), 3828874323);
      final random = SeededRandom(DailySeed.seedFor('2026-09-23'));
      expect(
        [for (var i = 0; i < 5; i++) random.nextInt(100)],
        [87, 84, 84, 49, 21],
      );
    });

    test('días distintos dan semillas distintas', () {
      final seeds = {
        for (var d = 1; d <= 365; d++)
          DailySeed.seedFor(
            DailySeed.dateKey(DateTime(2026).add(Duration(days: d))),
          ),
      };
      expect(seeds, hasLength(365));
    });

    test('nextInt se queda en rango y nextDouble en [0, 1)', () {
      final random = SeededRandom(42);
      for (var i = 0; i < 10000; i++) {
        expect(random.nextInt(7), inInclusiveRange(0, 6));
        final d = random.nextDouble();
        expect(d >= 0 && d < 1, isTrue);
      }
    });
  });

  group('DailyChallenge', () {
    test('el mismo día reparte el mismo tablero, a cualquier hora', () {
      final morning = DailyChallenge.forDate(DateTime(2026, 9, 23, 0, 1));
      final night = DailyChallenge.forDate(DateTime(2026, 9, 23, 23, 59));

      expect(morning, night);
      expect(_deal(morning), _deal(night));
    });

    test('días distintos reparten tableros distintos', () {
      final today = DailyChallenge.forDate(DateTime(2026, 9, 23));
      // Mismo índice de categoría (rotación de 3) para comparar solo el
      // reparto.
      final later = DailyChallenge.forDate(DateTime(2026, 9, 26));

      expect(later.category, today.category);
      expect(_deal(today), isNot(_deal(later)));
    });

    test('numera desde la época y no se desvía con el horario de verano', () {
      expect(DailyChallenge.forDate(DateTime(2026, 1, 1)).number, 1);
      // Cruza el cambio de hora de marzo y el de octubre/noviembre.
      expect(DailyChallenge.forDate(DateTime(2026, 4, 1)).number, 91);
      expect(DailyChallenge.forDate(DateTime(2026, 12, 31)).number, 365);
    });

    test('la configuración es fija, no adaptativa', () {
      final challenge = DailyChallenge.forDate(DateTime(2026, 9, 23));
      expect(challenge.settings.pairCount, DailyChallenge.pairCount);
    });
  });

  group('DailyStreak', () {
    test('cuenta días seguidos hasta hoy', () {
      final streak = DailyStreak.fromDates([
        '2026-09-21',
        '2026-09-22',
        '2026-09-23',
      ], '2026-09-23');
      expect(streak.current, 3);
      expect(streak.longest, 3);
    });

    test('sigue viva hoy si se completó ayer', () {
      final streak = DailyStreak.fromDates([
        '2026-09-21',
        '2026-09-22',
      ], '2026-09-23');
      expect(streak.current, 2);
    });

    test('se rompe al saltarse un día y recuerda la mejor', () {
      final streak = DailyStreak.fromDates([
        '2026-09-10',
        '2026-09-11',
        '2026-09-12',
        '2026-09-13',
        '2026-09-20',
      ], '2026-09-23');
      expect(streak.current, 0);
      expect(streak.longest, 4);
    });

    test('cruza meses y años', () {
      final streak = DailyStreak.fromDates([
        '2025-12-31',
        '2026-01-01',
      ], '2026-01-01');
      expect(streak.current, 2);
    });

    test('ignora claves malformadas', () {
      expect(DailyStreak.fromDates(['basura'], '2026-09-23').current, 0);
    });
  });

  group('DailyResult', () {
    DailyResult result({int hints = 0}) => DailyResult(
      dateKey: '2026-09-23',
      number: 266,
      elapsedSeconds: 42,
      moves: 14,
      hintsUsed: hints,
      score: 2790,
      columns: 4,
      grid: [for (final c in 'ggygggggyggr'.split('')) CardRating.fromCode(c)],
    );

    test('la cuadrícula tiene la forma del tablero', () {
      expect(result().emojiRows, ['🟩🟩🟨🟩', '🟩🟩🟩🟩', '🟨🟩🟩🟥']);
    });

    test('codificar y decodificar es simétrico', () {
      final encoded = result().encodedGrid;
      expect(encoded, 'ggyg|gggg|yggr');
      final decoded = DailyResult.decodeGrid(encoded);
      expect(decoded.columns, 4);
      expect(decoded.grid, result().grid);
    });

    test('la nota de cada carta sale de cuántas veces se volteó', () {
      expect(CardRating.forFlips(1), CardRating.sharp);
      expect(CardRating.forFlips(2), CardRating.sharp);
      expect(CardRating.forFlips(4), CardRating.close);
      expect(CardRating.forFlips(5), CardRating.struggled);
    });

    const strings = DailyShareStrings(
      challenge: 'Challenge',
      moves: 'moves',
      streakDays: 'day streak',
      callToAction: 'Try it today!',
    );

    test('el texto para compartir sigue el formato acordado', () {
      expect(
        DailyShareText.build(result: result(), streak: 5, strings: strings),
        '🧠 Memory Companion - Challenge #266\n'
        '⏱️ 42s | 🔄 14 moves\n'
        '🟩🟩🟨🟩\n'
        '🟩🟩🟩🟩\n'
        '🟨🟩🟩🟥\n'
        '🔥 5 day streak\n'
        'Try it today! ${DailyShareText.downloadUrl}',
      );
    });

    test('las pistas se declaran y una racha de 1 no se presume', () {
      final text = DailyShareText.build(
        result: result(hints: 2),
        streak: 1,
        strings: strings,
      );
      expect(text, contains('⏱️ 42s | 🔄 14 moves | 💡 2'));
      expect(text, isNot(contains('🔥')));
    });

    test('el tiempo pasa a minutos a partir de 60 s', () {
      expect(DailyShareText.formatDuration(59), '59s');
      expect(DailyShareText.formatDuration(65), '1m 05s');
    });
  });
}

/// The board as comparable data: each card's pair, in board order.
List<String> _deal(DailyChallenge challenge) => [
  for (final card in BoardFactory.deal(
    category: challenge.category,
    settings: challenge.settings,
    languageCode: 'es',
    random: challenge.random,
  ))
    card.pairId,
];
