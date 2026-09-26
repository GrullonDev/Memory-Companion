import 'dart:typed_data';

import 'package:memory_companion/features/game_context/model/place.dart';
import 'package:memory_companion/features/history_search/model/search_answer.dart';
import 'package:memory_companion/features/history_search/model/search_query.dart';
import 'package:memory_companion/features/history_search/service/query_parser.dart';
import 'package:memory_companion/features/history_search/service/text_embedder.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';

/// Every name a category goes by, in every language the app speaks.
typedef CategoryNames = List<String> Function(String categoryId);

/// The history, embedded once and searched many times.
///
/// Built from the local database whenever a game is stored or a place is
/// renamed. Everything, the vectors included, lives in memory on the
/// device.
class HistoryIndex {
  HistoryIndex({
    required List<GameStats> games,
    required this.places,
    required this.categoryNames,
    required this.embedder,
  }) : games = List.unmodifiable(games),
       vectors = [
         for (final game in games)
           embedder.embed(describe(game, places, categoryNames)),
       ];

  final List<GameStats> games;
  final List<Place> places;
  final CategoryNames categoryNames;
  final TextEmbedder embedder;

  /// One per game, in [games] order.
  final List<Float32List> vectors;

  /// The text a game is embedded from: what it was, when, where, with whom
  /// and how it went. Spanish words; the embedder folds English onto them.
  static String describe(
    GameStats game,
    List<Place> places,
    CategoryNames categoryNames,
  ) {
    final date = game.date.toLocal();
    final place = places.where((p) => p.id == game.placeId).firstOrNull;
    return [
      ...categoryNames(game.categoryId),
      _weekdays[date.weekday - 1],
      _months[date.month - 1],
      _slotWords[DaySlot.of(date)]!,
      if (game.won) 'ganada' else 'perdida',
      if (place != null && place.isNamed) place.name!,
      for (final player in game.nearby ?? const []) player.name ?? player.code,
    ].join(' ');
  }

  static const _weekdays = [
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo',
  ];
  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  static const _slotWords = {
    DaySlot.morning: 'manana',
    DaySlot.afternoon: 'tarde',
    DaySlot.evening: 'noche',
    DaySlot.night: 'madrugada',
  };
}

/// Answers questions about the history, entirely on the device.
///
/// The parser reads the shape of the question (best game, who, where,
/// when); the filters narrow the games to the dates, place, category and
/// person it names; then either a metric picks the answer or, for anything
/// else, the embeddings rank the games by similarity to the question.
class HistorySearchEngine {
  const HistorySearchEngine({this.parser = const QueryParser()});

  final QueryParser parser;

  static const int maxGames = 5;

  /// Below this many games a place or part of the day is still listed, but
  /// after those with enough games to be judged.
  static const int minGamesToRank = 2;

  SearchAnswer answer(String question, HistoryIndex index, DateTime now) {
    final query = parser.parse(question, now);
    final normalized = ' ${normalizeText(question)} ';

    final (placeIds, unmatchedPlace) = _resolvePlace(query, normalized, index);
    final category = _mentionedCategory(normalized, index);
    final person = _mentionedPerson(normalized, index);

    final picked = <int>[];
    for (var i = 0; i < index.games.length; i++) {
      final game = index.games[i];
      final date = game.date.toLocal();
      if (query.range != null && !query.range!.contains(date)) continue;
      if (query.weekday != null && date.weekday != query.weekday) continue;
      if (placeIds != null && !placeIds.contains(game.placeId)) continue;
      if (category != null && game.categoryId != category) continue;
      if (person != null &&
          !(game.nearby ?? const []).any((p) => p.code == person)) {
        continue;
      }
      picked.add(i);
    }
    final games = [for (final i in picked) index.games[i]];
    final placeFilter = placeIds?.length == 1 ? placeIds!.single : null;

    MissingAnswer missing(MissingData what) => MissingAnswer(
      missing: what,
      query: query,
      gamesConsidered: games.length,
      unmatchedPlace: unmatchedPlace,
      placeFilter: placeFilter,
      categoryFilter: category,
      personFilter: person,
    );

    // Comparing needs the games before the range too, so it filters itself.
    if (query.intent == SearchIntent.mostImproved) {
      return _mostImproved(query, index, now, placeIds, person) ??
          missing(MissingData.noComparison);
    }
    if (games.isEmpty) return missing(MissingData.noGames);

    switch (query.intent) {
      case SearchIntent.bestGame || SearchIntent.worstGame:
        final best = query.intent == SearchIntent.bestGame;
        final sorted = [...games]..sort((a, b) => _compareGames(a, b, best));
        return GameAnswer(
          game: sorted.first,
          best: best,
          query: query,
          gamesConsidered: games.length,
          unmatchedPlace: unmatchedPlace,
          placeFilter: placeFilter,
          categoryFilter: category,
          personFilter: person,
        );

      case SearchIntent.who:
        final looked = games.where((g) => g.nearby != null).toList();
        if (looked.isEmpty) return missing(MissingData.noNearby);
        final names = <String, String>{};
        final byCode = <String, List<GameStats>>{};
        for (final game in looked) {
          for (final player in game.nearby!) {
            byCode.putIfAbsent(player.code, () => []).add(game);
            if (player.name != null) names[player.code] = player.name!;
          }
        }
        final people = [
          for (final MapEntry(:key, :value) in byCode.entries)
            _tally(key, value),
        ]..sort((a, b) => b.games.compareTo(a.games));
        return PeopleAnswer(
          people: people,
          names: names,
          gamesAlone: looked.where((g) => g.nearby!.isEmpty).length,
          query: query,
          gamesConsidered: games.length,
          unmatchedPlace: unmatchedPlace,
          placeFilter: placeFilter,
          categoryFilter: category,
        );

      case SearchIntent.bestPlace:
        final placed = games.where((g) => g.placeId != null).toList();
        if (placed.isEmpty) return missing(MissingData.noPlaces);
        return PlaceAnswer(
          places: _ranked(_groupBy(placed, (g) => g.placeId!)),
          query: query,
          gamesConsidered: games.length,
          categoryFilter: category,
          personFilter: person,
        );

      case SearchIntent.bestTime:
        return TimeAnswer(
          slots: _ranked(_groupBy(games, (g) => DaySlot.of(g.date.toLocal()))),
          query: query,
          gamesConsidered: games.length,
          unmatchedPlace: unmatchedPlace,
          placeFilter: placeFilter,
          categoryFilter: category,
          personFilter: person,
        );

      case SearchIntent.count:
        return CountAnswer(
          wins: games.where((g) => g.won).length,
          query: query,
          gamesConsidered: games.length,
          unmatchedPlace: unmatchedPlace,
          placeFilter: placeFilter,
          categoryFilter: category,
          personFilter: person,
        );

      case SearchIntent.similar || SearchIntent.mostImproved:
        final target = index.embedder.embed(question);
        final scored = [
          for (final i in picked)
            (i: i, score: cosine(target, index.vectors[i])),
        ];
        // Newest first among equals, so a question with nothing to match
        // (or only filters) reads as "your latest games".
        scored.sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          if (byScore != 0) return byScore;
          return index.games[b.i].date.compareTo(index.games[a.i].date);
        });
        return GamesAnswer(
          games: [for (final s in scored.take(maxGames)) index.games[s.i]],
          query: query,
          gamesConsidered: games.length,
          unmatchedPlace: unmatchedPlace,
          placeFilter: placeFilter,
          categoryFilter: category,
          personFilter: person,
        );
    }
  }

  /// Higher score first; on a tie, the more precise and then the faster.
  static int _compareGames(GameStats a, GameStats b, bool best) {
    var order = b.score.compareTo(a.score);
    if (order == 0) order = b.accuracy.compareTo(a.accuracy);
    if (order == 0) order = a.timeSeconds.compareTo(b.timeSeconds);
    return best ? order : -order;
  }

  /// The category whose precision rose most: inside the range against
  /// before it, or, with nothing before, the second half of the range
  /// against the first.
  ImprovementAnswer? _mostImproved(
    SearchQuery query,
    HistoryIndex index,
    DateTime now,
    Set<int>? placeIds,
    String? person,
  ) {
    final range =
        query.range ??
        DateRange(
          DateTime(now.year, now.month, now.day - 29),
          DateTime(now.year, now.month, now.day + 1),
        );
    final games = [
      for (final game in index.games)
        if ((placeIds == null || placeIds.contains(game.placeId)) &&
            (person == null ||
                (game.nearby ?? const []).any((p) => p.code == person)) &&
            game.date.toLocal().isBefore(range.end))
          game,
    ]..sort((a, b) => a.date.compareTo(b.date));

    ImprovementAnswer? bestOf(
      Map<String, List<GameStats>> before,
      Map<String, List<GameStats>> after,
    ) {
      ImprovementAnswer? best;
      for (final category in after.keys) {
        final earlier = before[category];
        if (earlier == null || earlier.isEmpty) continue;
        final candidate = ImprovementAnswer(
          categoryId: category,
          before: _tally(category, earlier),
          after: _tally(category, after[category]!),
          query: query,
          gamesConsidered: after[category]!.length,
          placeFilter: placeIds?.length == 1 ? placeIds!.single : null,
          personFilter: person,
        );
        if (best == null || candidate.delta > best.delta) best = candidate;
      }
      return best;
    }

    final inRange = <String, List<GameStats>>{};
    final earlier = <String, List<GameStats>>{};
    for (final game in games) {
      final bucket = range.contains(game.date.toLocal()) ? inRange : earlier;
      bucket.putIfAbsent(game.categoryId, () => []).add(game);
    }
    final acrossRange = bestOf(earlier, inRange);
    if (acrossRange != null) return acrossRange;

    final firstHalf = <String, List<GameStats>>{};
    final secondHalf = <String, List<GameStats>>{};
    for (final MapEntry(key: category, value: list) in inRange.entries) {
      if (list.length < 2) continue;
      final middle = list.length ~/ 2;
      firstHalf[category] = list.sublist(0, middle);
      secondHalf[category] = list.sublist(middle);
    }
    return bestOf(firstHalf, secondHalf);
  }

  /// The places the question names, or the word it used when none matches.
  (Set<int>?, String?) _resolvePlace(
    SearchQuery query,
    String normalized,
    HistoryIndex index,
  ) {
    // "Lugar 2" / "place 2": the name shown for a place not yet named.
    final numbered = RegExp(r' (?:lugar|place) (\d+) ').firstMatch(normalized);
    if (numbered != null) {
      final ordinal = int.parse(numbered.group(1)!);
      if (ordinal >= 1 && ordinal <= index.places.length) {
        return ({index.places[ordinal - 1].id}, null);
      }
    }

    final words = tokenize(normalized).map(conceptOf).toSet();
    final mention = query.placeMention == null
        ? null
        : conceptOf(query.placeMention!);
    final matches = <int>{
      for (final place in index.places)
        if (place.isNamed)
          if (tokenize(place.name!).map(conceptOf).toSet() case final name
              when name.isNotEmpty &&
                  (name.every(words.contains) || name.contains(mention)))
            place.id,
    };
    if (matches.isNotEmpty) return (matches, null);
    return (null, query.placeMention);
  }

  String? _mentionedCategory(String normalized, HistoryIndex index) {
    String singular(String text) => text
        .split(' ')
        .map(
          (w) => w.length > 3 && w.endsWith('s')
              ? w.substring(0, w.length - 1)
              : w,
        )
        .join(' ');
    final question = singular(normalized);
    final ids = {for (final game in index.games) game.categoryId};
    for (final id in ids) {
      for (final name in index.categoryNames(id)) {
        final folded = singular(normalizeText(name));
        if (folded.isNotEmpty && question.contains(' $folded ')) return id;
      }
    }
    return null;
  }

  /// The friend code of someone recorded nearby whose name the question
  /// says.
  String? _mentionedPerson(String normalized, HistoryIndex index) {
    for (final game in index.games) {
      for (final player in game.nearby ?? const []) {
        final name = player.name;
        if (name == null) continue;
        final folded = normalizeText(name);
        if (folded.isNotEmpty && normalized.contains(' $folded ')) {
          return player.code;
        }
      }
    }
    return null;
  }

  static Map<K, List<GameStats>> _groupBy<K>(
    List<GameStats> games,
    K Function(GameStats) keyOf,
  ) {
    final groups = <K, List<GameStats>>{};
    for (final game in games) {
      groups.putIfAbsent(keyOf(game), () => []).add(game);
    }
    return groups;
  }

  static List<Tally<K>> _ranked<K>(Map<K, List<GameStats>> groups) {
    final tallies = [
      for (final MapEntry(:key, :value) in groups.entries) _tally(key, value),
    ];
    tallies.sort((a, b) {
      final aJudged = a.games >= minGamesToRank;
      final bJudged = b.games >= minGamesToRank;
      if (aJudged != bJudged) return aJudged ? -1 : 1;
      final byAccuracy = b.accuracy.compareTo(a.accuracy);
      if (byAccuracy != 0) return byAccuracy;
      return b.games.compareTo(a.games);
    });
    return tallies;
  }

  static Tally<K> _tally<K>(K key, List<GameStats> games) {
    var matched = 0;
    var moves = 0;
    for (final game in games) {
      matched += game.matchedPairs;
      moves += game.moves;
    }
    return Tally(
      key: key,
      games: games.length,
      matchedPairs: matched,
      moves: moves,
    );
  }
}
