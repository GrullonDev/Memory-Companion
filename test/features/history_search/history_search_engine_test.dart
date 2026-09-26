import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game_context/model/nearby_player.dart';
import 'package:memory_companion/features/game_context/model/place.dart';
import 'package:memory_companion/features/history_search/model/search_answer.dart';
import 'package:memory_companion/features/history_search/model/search_query.dart';
import 'package:memory_companion/features/history_search/service/history_search_engine.dart';
import 'package:memory_companion/features/history_search/service/query_parser.dart';
import 'package:memory_companion/features/history_search/service/text_embedder.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';

void main() {
  // Jueves 24 de septiembre de 2026.
  final now = DateTime(2026, 9, 24, 18);

  GameStats game(
    DateTime date, {
    String category = 'numeric',
    int score = 500,
    int matched = 6,
    int moves = 10,
    bool won = true,
    int? placeId,
    List<NearbyPlayer>? nearby,
  }) => GameStats(
    date: date,
    categoryId: category,
    pairCount: 6,
    matchedPairs: matched,
    moves: moves,
    memoryErrors: 0,
    hintsUsed: 0,
    timeSeconds: 60,
    timeLimitSeconds: 90,
    timed: true,
    won: won,
    score: score,
    placeId: placeId,
    nearby: nearby,
  );

  List<String> names(String id) => switch (id) {
    'numeric' => ['Números', 'Numbers'],
    'classic' => ['Clásico', 'Classic'],
    _ => [id],
  };

  const places = [
    Place(id: 1, name: 'Casa', latitude: 0, longitude: 0),
    Place(id: 2, name: 'Parque', latitude: 1, longitude: 1),
    Place(id: 3, latitude: 2, longitude: 2),
  ];
  const ana = NearbyPlayer(code: 'ANA234', name: 'Ana');
  const luis = NearbyPlayer(code: 'LUS567', name: 'Luis');

  HistoryIndex index(List<GameStats> games) => HistoryIndex(
    games: games,
    places: places,
    categoryNames: names,
    embedder: const LexicalEmbedder(),
  );

  const engine = HistorySearchEngine();

  group('QueryParser', () {
    const parser = QueryParser();

    test('"del viernes" es el último viernes; "los viernes", todos', () {
      final one = parser.parse('¿Cuál fue mi mejor partida del viernes?', now);
      expect(one.intent, SearchIntent.bestGame);
      expect(
        one.range,
        DateRange(DateTime(2026, 9, 18), DateTime(2026, 9, 19)),
      );

      final every = parser.parse('mejor partida los viernes', now);
      expect(every.range, isNull);
      expect(every.weekday, DateTime.friday);

      expect(parser.parse('best game on Fridays', now).weekday, 5);
    });

    test('semana pasada, este mes y últimos N días', () {
      final lastWeek = parser.parse(
        '¿Contra quién jugué la semana pasada en el parque?',
        now,
      );
      expect(lastWeek.intent, SearchIntent.who);
      expect(
        lastWeek.range,
        DateRange(DateTime(2026, 9, 14), DateTime(2026, 9, 21)),
      );
      expect(lastWeek.placeMention, 'parque');

      final month = parser.parse('¿En qué categoría mejoré más este mes?', now);
      expect(month.intent, SearchIntent.mostImproved);
      expect(month.range, DateRange(DateTime(2026, 9), DateTime(2026, 10)));
      expect(month.placeMention, isNull, reason: '"en qué" no es un lugar');

      expect(
        parser.parse('games in the last 3 days', now).range,
        DateRange(DateTime(2026, 9, 22), DateTime(2026, 9, 25)),
      );
    });

    test('reconoce dónde, cuándo y cuántas, en los dos idiomas', () {
      expect(
        parser.parse('¿Dónde me concentro mejor?', now).intent,
        SearchIntent.bestPlace,
      );
      expect(
        parser.parse('¿A qué hora rindo mejor?', now).intent,
        SearchIntent.bestTime,
      );
      expect(
        parser.parse('How many games did I win this week?', now).intent,
        SearchIntent.count,
      );
      expect(
        parser.parse('Who did I play with yesterday?', now).intent,
        SearchIntent.who,
      );
      expect(
        parser.parse('partidas en marzo', now).range,
        DateRange(DateTime(2026, 3), DateTime(2026, 4)),
      );
    });
  });

  group('HistorySearchEngine', () {
    test('la mejor partida del viernes', () {
      final history = index([
        game(DateTime(2026, 9, 18, 10), score: 300),
        game(DateTime(2026, 9, 18, 20), score: 900, category: 'classic'),
        game(DateTime(2026, 9, 11, 10), score: 2000),
        game(DateTime(2026, 9, 23, 10), score: 5000),
      ]);
      final answer = engine.answer(
        '¿Cuál fue mi mejor partida del viernes?',
        history,
        now,
      );
      expect(answer, isA<GameAnswer>());
      answer as GameAnswer;
      expect(answer.game.score, 900);
      expect(answer.gamesConsidered, 2);
    });

    test('la categoría que más mejoró este mes', () {
      final history = index([
        // Antes de septiembre: Números 50 %, Clásico 60 %.
        game(DateTime(2026, 8, 20), matched: 5, moves: 10),
        game(DateTime(2026, 8, 21), category: 'classic', matched: 6),
        // Septiembre: Números 100 %, Clásico 60 %.
        game(DateTime(2026, 9, 10), matched: 6, moves: 6),
        game(DateTime(2026, 9, 12), category: 'classic', matched: 6),
      ]);
      final answer = engine.answer(
        '¿En qué categoría mejoré más este mes?',
        history,
        now,
      );
      expect(answer, isA<ImprovementAnswer>());
      answer as ImprovementAnswer;
      expect(answer.categoryId, 'numeric');
      expect(answer.before.accuracy, closeTo(0.5, 1e-9));
      expect(answer.after.accuracy, closeTo(1.0, 1e-9));
    });

    test('contra quién jugué la semana pasada en el parque', () {
      final history = index([
        game(DateTime(2026, 9, 15), placeId: 2, nearby: [ana, luis]),
        game(DateTime(2026, 9, 17), placeId: 2, nearby: [ana]),
        // En casa, o fuera de la semana: no cuentan.
        game(DateTime(2026, 9, 16), placeId: 1, nearby: [luis]),
        game(DateTime(2026, 9, 22), placeId: 2, nearby: [luis]),
      ]);
      final answer = engine.answer(
        '¿Contra quién jugué la semana pasada en el parque?',
        history,
        now,
      );
      expect(answer, isA<PeopleAnswer>());
      answer as PeopleAnswer;
      expect(answer.placeFilter, 2);
      expect([for (final p in answer.people) p.key], ['ANA234', 'LUS567']);
      expect(answer.people.first.games, 2);
      expect(answer.names['ANA234'], 'Ana');
    });

    test('un lugar que no existe se dice, no se inventa', () {
      final history = index([
        game(DateTime(2026, 9, 15), nearby: [ana]),
      ]);
      final answer = engine.answer(
        '¿Contra quién jugué en la playa?',
        history,
        now,
      );
      expect(answer.unmatchedPlace, 'playa');
      expect(answer.placeFilter, isNull);
    });

    test('sin "personas cercanas" activado no hay a quién nombrar', () {
      final answer = engine.answer(
        '¿Con quién jugué?',
        index([game(DateTime(2026, 9, 15))]),
        now,
      );
      expect(answer, isA<MissingAnswer>());
      expect((answer as MissingAnswer).missing, MissingData.noNearby);
    });

    test('dónde y a qué hora rinde más la memoria', () {
      final history = index([
        game(DateTime(2026, 9, 1, 9), placeId: 1, matched: 6, moves: 12),
        game(DateTime(2026, 9, 2, 9), placeId: 1, matched: 6, moves: 12),
        game(DateTime(2026, 9, 3, 20), placeId: 2, matched: 6, moves: 6),
        game(DateTime(2026, 9, 4, 20), placeId: 2, matched: 6, moves: 7),
      ]);
      final where = engine.answer('¿Dónde me concentro mejor?', history, now);
      expect((where as PlaceAnswer).places.first.key, 2);

      final when = engine.answer('¿A qué hora rindo mejor?', history, now);
      expect((when as TimeAnswer).slots.first.key, DaySlot.evening);
    });

    test('filtra por la categoría y la persona que se nombran', () {
      final history = index([
        game(DateTime(2026, 9, 20), score: 100, nearby: [ana]),
        game(DateTime(2026, 9, 21), score: 800, category: 'classic'),
        game(DateTime(2026, 9, 22), score: 400, nearby: [luis]),
      ]);
      final numbers = engine.answer('mejor partida de números', history, now);
      expect((numbers as GameAnswer).game.score, 400);
      expect(numbers.categoryFilter, 'numeric');

      final withAna = engine.answer('¿Cuántas partidas con Ana?', history, now);
      expect(withAna, isA<CountAnswer>());
      expect(withAna.gamesConsidered, 1);
      expect(withAna.personFilter, 'ANA234');
    });

    test('"Lugar 3" encuentra un lugar sin nombre', () {
      final history = index([
        game(DateTime(2026, 9, 20), placeId: 3),
        game(DateTime(2026, 9, 21), placeId: 1),
      ]);
      final answer = engine.answer('cuántas partidas en lugar 3', history, now);
      expect(answer.gamesConsidered, 1);
      expect(answer.placeFilter, 3);
    });

    test('lo demás se busca por parecido, en cualquier idioma', () {
      final history = index([
        game(DateTime(2026, 9, 18, 9), category: 'classic', won: false),
        game(DateTime(2026, 9, 19, 21), won: true, placeId: 2),
        game(DateTime(2026, 9, 20, 15), category: 'classic'),
      ]);
      final answer = engine.answer('numbers at the park', history, now);
      expect(answer, isA<GamesAnswer>());
      expect((answer as GamesAnswer).games.first.date.day, 19);
    });
  });

  group('LexicalEmbedder', () {
    const embedder = LexicalEmbedder();

    test('español e inglés caen en los mismos conceptos', () {
      final friday = embedder.embed('viernes ganada');
      expect(cosine(friday, embedder.embed('Friday won')), closeTo(1, 1e-3));
      expect(cosine(friday, embedder.embed('lunes perdida')), lessThan(0.3));
    });

    test('tolera tildes y plurales', () {
      final a = embedder.embed('números');
      expect(cosine(a, embedder.embed('numero')), greaterThan(0.5));
      expect(embedder.embed('de la el').every((v) => v == 0), isTrue);
    });
  });
}
