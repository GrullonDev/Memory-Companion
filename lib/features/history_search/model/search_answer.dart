import 'package:memory_companion/features/history_search/model/search_query.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';

/// Part of the day, as the search groups games.
enum DaySlot {
  morning,
  afternoon,
  evening,
  night;

  static DaySlot of(DateTime moment) => switch (moment.hour) {
    >= 6 && < 12 => morning,
    >= 12 && < 19 => afternoon,
    >= 19 && < 23 => evening,
    _ => night,
  };
}

/// Games pooled under one key, with the precision of the pool.
class Tally<K> {
  const Tally({
    required this.key,
    required this.games,
    required this.matchedPairs,
    required this.moves,
  });

  final K key;
  final int games;
  final int matchedPairs;
  final int moves;

  /// Σ matched pairs / Σ turns, like the statistics panel: a 12-pair board
  /// weighs more than a 3-pair one.
  double get accuracy => moves == 0 ? 0 : matchedPairs / moves;
}

/// Why a question has no answer the history can give.
enum MissingData {
  /// No game matches the filters.
  noGames,

  /// "Nearby players" was never on, so nobody was recorded.
  noNearby,

  /// Location was never on, so no game has a place.
  noPlaces,

  /// No category has games on both sides of the comparison.
  noComparison,
}

/// The answer to one question.
///
/// Carries structure, not sentences: the screen words it in the player's
/// language.
sealed class SearchAnswer {
  const SearchAnswer({
    required this.query,
    required this.gamesConsidered,
    this.unmatchedPlace,
    this.placeFilter,
    this.categoryFilter,
    this.personFilter,
  });

  final SearchQuery query;

  /// How many games survived the filters.
  final int gamesConsidered;

  /// A place the question named that the player has no place called.
  final String? unmatchedPlace;

  /// Filters taken from the question, to show what was understood.
  final int? placeFilter;
  final String? categoryFilter;
  final String? personFilter;
}

class GameAnswer extends SearchAnswer {
  const GameAnswer({
    required this.game,
    required this.best,
    required super.query,
    required super.gamesConsidered,
    super.unmatchedPlace,
    super.placeFilter,
    super.categoryFilter,
    super.personFilter,
  });

  final GameStats game;

  /// False for "worst".
  final bool best;
}

class ImprovementAnswer extends SearchAnswer {
  const ImprovementAnswer({
    required this.categoryId,
    required this.before,
    required this.after,
    required super.query,
    required super.gamesConsidered,
    super.unmatchedPlace,
    super.placeFilter,
    super.personFilter,
  });

  final String categoryId;
  final Tally<String> before;
  final Tally<String> after;

  double get delta => after.accuracy - before.accuracy;
}

/// People, most frequent first. `key` is the friend code.
class PeopleAnswer extends SearchAnswer {
  const PeopleAnswer({
    required this.people,
    required this.names,
    required this.gamesAlone,
    required super.query,
    required super.gamesConsidered,
    super.unmatchedPlace,
    super.placeFilter,
    super.categoryFilter,
  });

  final List<Tally<String>> people;

  /// The name each code was recorded under, when it was known.
  final Map<String, String> names;

  /// Games where someone looked and nobody was around.
  final int gamesAlone;
}

/// Places, most precise first. `key` is `Places.id`.
class PlaceAnswer extends SearchAnswer {
  const PlaceAnswer({
    required this.places,
    required super.query,
    required super.gamesConsidered,
    super.categoryFilter,
    super.personFilter,
  });

  final List<Tally<int>> places;
}

/// Parts of the day, most precise first.
class TimeAnswer extends SearchAnswer {
  const TimeAnswer({
    required this.slots,
    required super.query,
    required super.gamesConsidered,
    super.unmatchedPlace,
    super.placeFilter,
    super.categoryFilter,
    super.personFilter,
  });

  final List<Tally<DaySlot>> slots;
}

class CountAnswer extends SearchAnswer {
  const CountAnswer({
    required this.wins,
    required super.query,
    required super.gamesConsidered,
    super.unmatchedPlace,
    super.placeFilter,
    super.categoryFilter,
    super.personFilter,
  });

  final int wins;
}

/// The games closest to the question, best match first.
class GamesAnswer extends SearchAnswer {
  const GamesAnswer({
    required this.games,
    required super.query,
    required super.gamesConsidered,
    super.unmatchedPlace,
    super.placeFilter,
    super.categoryFilter,
    super.personFilter,
  });

  final List<GameStats> games;
}

class MissingAnswer extends SearchAnswer {
  const MissingAnswer({
    required this.missing,
    required super.query,
    required super.gamesConsidered,
    super.unmatchedPlace,
    super.placeFilter,
    super.categoryFilter,
    super.personFilter,
  });

  final MissingData missing;
}
