/// One puzzle: the letters on the wheel and the words hidden in the grid.
///
/// Every word can be spelt with the wheel's letters, each letter used at
/// most as many times as it appears. Words are uppercase and have no
/// accents or `Ñ`, so the wheel never needs a diacritic key.
class CrosswordLevel {
  const CrosswordLevel(this.letters, this.words);

  final String letters;
  final List<String> words;
}

/// Shortest word the game accepts.
const crosswordMinWordLength = 3;

/// The puzzles per language, easiest first. After the last one the player
/// starts over from the first, with the level number still counting up.
abstract final class CrosswordLevels {
  static const Map<String, List<CrosswordLevel>> _byLanguage = {
    'es': [
      CrosswordLevel('SOL', ['SOL', 'LOS']),
      CrosswordLevel('CASA', ['CASA', 'SACA', 'ASA']),
      CrosswordLevel('PERA', ['PERA', 'PAR', 'ERA']),
      CrosswordLevel('RATO', ['RATO', 'ROTA', 'OTRA', 'ORA']),
      CrosswordLevel('SOLA', ['SOLA', 'LOSA', 'OLA', 'SAL']),
      CrosswordLevel('AMOR', ['AMOR', 'RAMO', 'MORA', 'MAR']),
      CrosswordLevel('PLATO', ['PLATO', 'PALO', 'PATO', 'ALTO']),
      CrosswordLevel('GATOS', ['GATOS', 'GASTO', 'GATO', 'TOGA', 'OSA']),
      CrosswordLevel('MANOS', ['MANOS', 'MANO', 'SANO', 'NOS', 'SON']),
      CrosswordLevel('CARTA', ['CARTA', 'CARA', 'RATA', 'ARCA', 'ACTA']),
      CrosswordLevel('CAMPO', ['CAMPO', 'COMA', 'POCA', 'OCA']),
      CrosswordLevel('TIERRA', ['TIERRA', 'TIRA', 'ARTE', 'AIRE']),
    ],
    'en': [
      CrosswordLevel('CAT', ['CAT', 'ACT']),
      CrosswordLevel('EAT', ['EAT', 'TEA', 'ATE']),
      CrosswordLevel('STOP', ['STOP', 'POTS', 'SPOT', 'POST', 'TOP']),
      CrosswordLevel('STORM', ['STORM', 'SORT', 'MOST', 'ROT']),
      CrosswordLevel('NIGHT', ['NIGHT', 'THING', 'THIN', 'HINT', 'HIT']),
      CrosswordLevel('BREAD', ['BREAD', 'BEARD', 'BARE', 'READ', 'BED']),
      CrosswordLevel('WATER', ['WATER', 'WEAR', 'TEAR', 'RATE', 'WET']),
      CrosswordLevel('HEART', ['HEART', 'EARTH', 'HATE', 'TEAR', 'ART']),
      CrosswordLevel('PLANE', ['PLANE', 'PANEL', 'LANE', 'LEAP', 'PEN']),
      CrosswordLevel('LISTEN', ['LISTEN', 'SILENT', 'TILE', 'LINE', 'NEST']),
      CrosswordLevel('GARDEN', ['GARDEN', 'DANGER', 'RANGE', 'GRADE', 'END']),
      CrosswordLevel('FRIEND', ['FRIEND', 'FIND', 'FINE', 'RIDE', 'DINE']),
    ],
  };

  /// The puzzles for [languageCode]; Spanish for a language without its own.
  static List<CrosswordLevel> forLanguage(String languageCode) =>
      _byLanguage[languageCode] ?? _byLanguage['es']!;

  static Iterable<String> get languages => _byLanguage.keys;
}
