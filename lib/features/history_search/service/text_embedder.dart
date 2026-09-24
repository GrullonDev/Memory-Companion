import 'dart:math' as math;
import 'dart:typed_data';

/// Turns text into a vector whose cosine similarity says how related two
/// texts are.
///
/// The search only depends on this interface, so an on-device neural model
/// can replace [LexicalEmbedder] later without touching anything else. The
/// one rule: it must run on the device. History text never leaves it.
abstract interface class TextEmbedder {
  int get dimensions;

  /// A unit-length vector, or all zeros for text with no content.
  Float32List embed(String text);
}

/// Cosine similarity of two unit vectors.
double cosine(Float32List a, Float32List b) {
  var dot = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
  }
  return dot;
}

/// A small, fully local embedding: hashed concepts plus character trigrams.
///
/// Words are first folded to a shared concept, across Spanish and English
/// ("viernes" and "Friday" are both `dow5`, "gané" and "won" are both
/// `won`), so a question in either language meets the same history. The
/// trigrams catch plurals, typos and missing accents ("numero" still meets
/// "Números"). Each feature lands in one of [dimensions] buckets with a
/// hashed sign, the classic hashing trick.
///
/// It knows words, not meaning: "happy" and "glad" only meet if the lexicon
/// says so. For a history made of game names, days, places and people that
/// is most of what matters, and it costs microseconds with no model file.
class LexicalEmbedder implements TextEmbedder {
  const LexicalEmbedder({this.dimensions = 512});

  @override
  final int dimensions;

  static const double _conceptWeight = 1.0;
  static const double _trigramWeight = 0.35;

  @override
  Float32List embed(String text) {
    final vector = Float32List(dimensions);
    for (final word in tokenize(text)) {
      final concept = _concepts[word];
      if (concept != null) {
        // A known concept is the whole meaning: its spelling in one
        // language must not pull it away from the other.
        _add(vector, 'c:$concept', _conceptWeight);
        continue;
      }
      _add(vector, 'c:${_singular(word)}', _conceptWeight);
      final padded = '#$word#';
      if (padded.length < 5) continue;
      for (var i = 0; i + 3 <= padded.length; i++) {
        _add(vector, 't:${padded.substring(i, i + 3)}', _trigramWeight);
      }
    }
    var norm = 0.0;
    for (final value in vector) {
      norm += value * value;
    }
    if (norm == 0) return vector;
    final scale = 1 / math.sqrt(norm);
    for (var i = 0; i < vector.length; i++) {
      vector[i] *= scale;
    }
    return vector;
  }

  /// Drops a plural "s" ("números" → "numero", "games" → "game"). Crude,
  /// and enough: the trigrams cover what it misses.
  static String _singular(String word) => word.length > 4 && word.endsWith('s')
      ? word.substring(0, word.length - 1)
      : word;

  void _add(Float32List vector, String feature, double weight) {
    final hash = _fnv1a32(feature);
    final sign = (hash & 0x80000000) == 0 ? 1.0 : -1.0;
    vector[hash % dimensions] += sign * weight;
  }

  static int _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }
}

/// Lower case, accents removed, anything but letters and digits as spaces.
String normalizeText(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    buffer.write(_folded[char] ?? (_wordChar.hasMatch(char) ? char : ' '));
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// The content words of [text], normalized, without stop words.
List<String> tokenize(String text) => [
  for (final word in normalizeText(text).split(' '))
    if (word.isNotEmpty && !stopWords.contains(word)) word,
];

/// The concept a normalized word stands for, or the word itself.
String conceptOf(String word) => _concepts[word] ?? word;

final _wordChar = RegExp('[a-z0-9]');

const _folded = {
  'á': 'a',
  'à': 'a',
  'ä': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ë': 'e',
  'ê': 'e',
  'í': 'i',
  'ì': 'i',
  'ï': 'i',
  'î': 'i',
  'ó': 'o',
  'ò': 'o',
  'ö': 'o',
  'ô': 'o',
  'ú': 'u',
  'ù': 'u',
  'ü': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Words that carry no meaning for the search, in both languages.
const Set<String> stopWords = {
  // Español.
  'a', 'al', 'cual', 'cuales', 'de', 'del', 'el', 'en', 'es', 'esa', 'ese',
  'fue', 'fueron', 'ha', 'he', 'la', 'las', 'lo', 'los', 'me', 'mi', 'mis',
  'o', 'por', 'para', 'que', 'se', 'su', 'sus', 'un', 'una', 'unos', 'y',
  'yo', 'con', 'contra', 'como', 'mas', 'muy', 'tu', 'tus', 'jugue',
  'juego', 'juegos', 'jugar', 'jugado', 'partida', 'partidas', 'hice',
  // English.
  'an', 'and', 'at', 'did', 'do', 'for', 'i', 'in', 'is', 'it', 'my',
  'of', 'on', 'or', 'the', 'to', 'was', 'were', 'what', 'which', 'with',
  'against', 'played', 'play', 'game', 'games', 'match', 'matches', 'had',
};

/// Spanish and English words folded to one concept.
const Map<String, String> _concepts = {
  // Days of the week, Monday = 1.
  'lunes': 'dow1', 'monday': 'dow1', 'mondays': 'dow1',
  'martes': 'dow2', 'tuesday': 'dow2', 'tuesdays': 'dow2',
  'miercoles': 'dow3', 'wednesday': 'dow3', 'wednesdays': 'dow3',
  'jueves': 'dow4', 'thursday': 'dow4', 'thursdays': 'dow4',
  'viernes': 'dow5', 'friday': 'dow5', 'fridays': 'dow5',
  'sabado': 'dow6', 'sabados': 'dow6', 'saturday': 'dow6', 'saturdays': 'dow6',
  'domingo': 'dow7', 'domingos': 'dow7', 'sunday': 'dow7', 'sundays': 'dow7',
  // Months.
  'enero': 'mon1', 'january': 'mon1',
  'febrero': 'mon2', 'february': 'mon2',
  'marzo': 'mon3', 'march': 'mon3',
  'abril': 'mon4', 'april': 'mon4',
  'mayo': 'mon5', 'may': 'mon5',
  'junio': 'mon6', 'june': 'mon6',
  'julio': 'mon7', 'july': 'mon7',
  'agosto': 'mon8', 'august': 'mon8',
  'septiembre': 'mon9', 'setiembre': 'mon9', 'september': 'mon9',
  'octubre': 'mon10', 'october': 'mon10',
  'noviembre': 'mon11', 'november': 'mon11',
  'diciembre': 'mon12', 'december': 'mon12',
  // Parts of the day.
  'manana': 'morning', 'mananas': 'morning', 'morning': 'morning',
  'mornings': 'morning',
  'tarde': 'afternoon', 'tardes': 'afternoon', 'afternoon': 'afternoon',
  'afternoons': 'afternoon',
  'noche': 'night', 'noches': 'night', 'night': 'night', 'nights': 'night',
  'evening': 'night', 'evenings': 'night', 'madrugada': 'night',
  // Outcome.
  'gane': 'won', 'ganada': 'won', 'ganadas': 'won', 'ganado': 'won',
  'victoria': 'won', 'victorias': 'won', 'won': 'won', 'win': 'won',
  'wins': 'won', 'ganar': 'won',
  'perdi': 'lost', 'perdida': 'lost', 'perdidas': 'lost', 'derrota': 'lost',
  'derrotas': 'lost', 'lost': 'lost', 'lose': 'lost', 'loss': 'lost',
  'losses': 'lost',
  // Common places.
  'casa': 'home', 'hogar': 'home', 'home': 'home', 'house': 'home',
  'parque': 'park', 'park': 'park',
  'trabajo': 'work', 'oficina': 'work', 'work': 'work', 'office': 'work',
  'escuela': 'school', 'colegio': 'school', 'school': 'school',
  'universidad': 'school', 'university': 'school',
};
