import 'package:memory_companion/features/history_search/model/search_query.dart';
import 'package:memory_companion/features/history_search/service/text_embedder.dart';

/// Takes a question in Spanish or English apart: what it asks, when, and
/// where.
///
/// Rules, not a model. The questions people ask about their own history
/// come in a handful of shapes, and a rule that misfires is easy to see and
/// fix; whatever the rules do not claim falls through to similarity search.
class QueryParser {
  const QueryParser();

  SearchQuery parse(String text, DateTime now) {
    final normalized = normalizeText(text);
    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    bool has(Set<String> options) => words.any(options.contains);
    bool hasPhrase(List<String> phrases) =>
        phrases.any((p) => ' $normalized '.contains(' $p '));

    final range = _range(words, hasPhrase, now);
    final (weekday, recurring) = _weekday(words);
    final DateRange? effective;
    if (weekday != null && !recurring) {
      effective = _dayInRange(weekday, range, now);
    } else {
      effective = range ?? (weekday == null ? _month(words, now) : null);
    }

    return SearchQuery(
      text: text,
      intent: _intent(has, hasPhrase),
      range: effective,
      weekday: recurring ? weekday : null,
      placeMention: _placeMention(normalized),
    );
  }

  SearchIntent _intent(
    bool Function(Set<String>) has,
    bool Function(List<String>) hasPhrase,
  ) {
    final best = has(_best);
    final worst = has(_worst);
    if (has(_who)) return SearchIntent.who;
    if (has(_improved)) return SearchIntent.mostImproved;
    if (has(_count) || hasPhrase(['how many'])) return SearchIntent.count;
    if ((best || worst) && has(_gameNouns)) {
      return best ? SearchIntent.bestGame : SearchIntent.worstGame;
    }
    if (has(_where)) return SearchIntent.bestPlace;
    if (has(_when) || hasPhrase(['what time', 'time of day'])) {
      return SearchIntent.bestTime;
    }
    if (best) return SearchIntent.bestGame;
    if (worst) return SearchIntent.worstGame;
    return SearchIntent.similar;
  }

  DateRange? _range(
    List<String> words,
    bool Function(List<String>) hasPhrase,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    DateTime day(int offset) =>
        DateTime(today.year, today.month, today.day + offset);
    final weekStart = day(1 - today.weekday);

    if (words.contains('hoy') || words.contains('today')) {
      return DateRange(today, day(1));
    }
    if (words.contains('ayer') || words.contains('yesterday')) {
      return DateRange(day(-1), today);
    }
    final lastDays = RegExp(
      r'\b(?:ultimos|last|past) (\d{1,3}) (?:dias|days)\b',
    ).firstMatch(words.join(' '));
    if (lastDays != null) {
      final count = int.parse(lastDays.group(1)!);
      return DateRange(day(1 - count), day(1));
    }
    if (hasPhrase([
      'semana pasada',
      'semana anterior',
      'ultima semana',
      'last week',
      'past week',
    ])) {
      return DateRange(
        DateTime(weekStart.year, weekStart.month, weekStart.day - 7),
        weekStart,
      );
    }
    if (hasPhrase(['esta semana', 'this week'])) {
      return DateRange(
        weekStart,
        DateTime(weekStart.year, weekStart.month, weekStart.day + 7),
      );
    }
    if (hasPhrase(['mes pasado', 'mes anterior', 'last month', 'past month'])) {
      return DateRange(
        DateTime(today.year, today.month - 1),
        DateTime(today.year, today.month),
      );
    }
    if (hasPhrase(['este mes', 'this month'])) {
      return DateRange(
        DateTime(today.year, today.month),
        DateTime(today.year, today.month + 1),
      );
    }
    if (hasPhrase(['este ano', 'this year'])) {
      return DateRange(DateTime(today.year), DateTime(today.year + 1));
    }
    return null;
  }

  /// The weekday named, and whether it recurs ("los viernes", "Fridays")
  /// rather than meaning one day ("el viernes", "on Friday").
  (int?, bool) _weekday(List<String> words) {
    for (var i = 0; i < words.length; i++) {
      final concept = conceptOf(words[i]);
      if (!concept.startsWith('dow')) continue;
      final weekday = int.parse(concept.substring(3));
      final previous = i > 0 ? words[i - 1] : '';
      // "lunes" to "viernes" are the same in the plural, so Spanish needs
      // the article; English and "sábados"/"domingos" show it in the word.
      final recurring =
          const {'los', 'every', 'cada'}.contains(previous) ||
          words[i].endsWith('days') ||
          words[i] == 'sabados' ||
          words[i] == 'domingos';
      return (weekday, recurring);
    }
    return (null, false);
  }

  /// One day: [weekday] inside [range] when the question gives a week
  /// ("el viernes de la semana pasada"), otherwise the latest one up to
  /// today.
  DateRange _dayInRange(int weekday, DateRange? range, DateTime now) {
    if (range != null && range.end.difference(range.start).inDays == 7) {
      final start = range.start;
      final day = DateTime(start.year, start.month, start.day + weekday - 1);
      return DateRange(day, DateTime(day.year, day.month, day.day + 1));
    }
    final today = DateTime(now.year, now.month, now.day);
    final back = (today.weekday - weekday) % 7;
    final day = DateTime(today.year, today.month, today.day - back);
    return DateRange(day, DateTime(day.year, day.month, day.day + 1));
  }

  /// A month by name: its most recent occurrence up to now.
  DateRange? _month(List<String> words, DateTime now) {
    for (final word in words) {
      final concept = conceptOf(word);
      if (!concept.startsWith('mon')) continue;
      final month = int.parse(concept.substring(3));
      final year = month <= now.month ? now.year : now.year - 1;
      return DateRange(DateTime(year, month), DateTime(year, month + 1));
    }
    return null;
  }

  String? _placeMention(String normalized) {
    final match = RegExp(
      r'\b(?:en|at|in|del|desde|from)(?: (?:el|la|los|las|the|mi|my))? ([a-z0-9]+)',
    ).allMatches(normalized);
    for (final m in match) {
      final word = m.group(1)!;
      if (stopWords.contains(word) || _notPlaces.contains(word)) continue;
      final concept = conceptOf(word);
      if (_timeConcept.hasMatch(concept)) continue;
      return word;
    }
    return null;
  }

  static final _timeConcept = RegExp(
    r'^(dow\d|mon\d+|morning|afternoon|night|won|lost)$',
  );

  static const _notPlaces = {
    'semana',
    'week',
    'mes',
    'month',
    'ano',
    'year',
    'hoy',
    'today',
    'ayer',
    'yesterday',
    'dia',
    'day',
    'ultimos',
    'last',
    'past',
    'this',
    'este',
    'esta',
    'categoria',
    'category',
    'hora',
    'time',
    'total',
    'general',
    'mejor',
    'best',
    'peor',
    'worst',
    'promedio',
    'average',
    'which',
    'what',
    'cual',
    'que',
    'quien',
    'who',
    'numeros',
    'palabras',
    'digitos',
  };

  static const _best = {
    'mejor',
    'mejores',
    'best',
    'record',
    'highest',
    'maxima',
    'maximo',
    'top',
  };
  static const _worst = {'peor', 'peores', 'worst', 'lowest', 'minima'};
  static const _who = {'quien', 'quienes', 'who', 'whom'};
  static const _improved = {
    'mejore',
    'mejorado',
    'mejoraste',
    'mejora',
    'improve',
    'improved',
    'improvement',
    'progrese',
    'progresado',
    'progress',
    'progressed',
    'avance',
    'avanzado',
  };
  static const _count = {'cuantas', 'cuantos', 'count'};
  static const _gameNouns = {
    'partida',
    'partidas',
    'juego',
    'game',
    'match',
    'resultado',
    'result',
    'score',
    'puntuacion',
    'puntaje',
    'ronda',
    'round',
  };
  static const _where = {'donde', 'where', 'lugar', 'lugares', 'place'};
  static const _when = {
    'hora',
    'horas',
    'horario',
    'momento',
    'cuando',
    'when',
  };
}
