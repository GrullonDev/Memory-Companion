/// What a question asks for.
enum SearchIntent {
  /// "¿Cuál fue mi mejor partida…?"
  bestGame,
  worstGame,

  /// "¿En qué categoría mejoré más…?"
  mostImproved,

  /// "¿Contra quién jugué…?"
  who,

  /// "¿Dónde me concentro mejor?"
  bestPlace,

  /// "¿A qué hora rindo mejor?"
  bestTime,

  /// "¿Cuántas partidas…?"
  count,

  /// Anything else: the games most similar to the question.
  similar,
}

/// A span of local time, [start] inclusive and [end] exclusive.
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start, $end)';
}

/// A question, taken apart.
class SearchQuery {
  const SearchQuery({
    required this.text,
    required this.intent,
    this.range,
    this.weekday,
    this.placeMention,
  });

  final String text;
  final SearchIntent intent;

  /// When the games happened, if the question says.
  final DateRange? range;

  /// A recurring weekday ("los viernes", "on Fridays"), Monday = 1.
  final int? weekday;

  /// Words after "en el…" / "at the…" that name no time: a place the
  /// question refers to, whether or not the player has one by that name.
  final String? placeMention;
}
