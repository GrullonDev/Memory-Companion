import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_layout.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_levels.dart';

/// Whether [word] can be spelt with [letters], each used at most once.
bool _spellable(String word, String letters) {
  final pool = letters.split('');
  for (final letter in word.split('')) {
    if (!pool.remove(letter)) return false;
  }
  return true;
}

void main() {
  for (final language in CrosswordLevels.languages) {
    group('niveles "$language"', () {
      final levels = CrosswordLevels.forLanguage(language);

      test('cada palabra se forma con las letras de la rueda', () {
        for (final level in levels) {
          expect(level.words.toSet(), hasLength(level.words.length));
          expect(level.letters, matches(RegExp(r'^[A-Z]+$')));
          for (final word in level.words) {
            expect(word, matches(RegExp(r'^[A-Z]+$')));
            expect(word.length, greaterThanOrEqualTo(crosswordMinWordLength));
            expect(
              _spellable(word, level.letters),
              isTrue,
              reason: '$word con ${level.letters}',
            );
          }
        }
      });

      test('cada nivel se arma como crucigrama', () {
        for (final level in levels) {
          final layout = CrosswordLayout.build(level.words);
          expect(
            layout.words.map((w) => w.word).toSet(),
            level.words.toSet(),
          );
          // Cada palabra se lee en la cuadrícula en su posición.
          for (final placed in layout.words) {
            final read = placed.cells.map((c) => layout.letters[c]).join();
            expect(read, placed.word);
          }
          // Las palabras solo se tocan donde se cruzan: toda secuencia de
          // letras seguidas, en fila o en columna, es una palabra del nivel.
          final words = level.words.toSet();
          for (final run in _allRuns(layout)) {
            expect(words, contains(run), reason: level.letters);
          }
          // Todo cabe en una pantalla de teléfono.
          expect(layout.cols, lessThanOrEqualTo(10), reason: level.letters);
          expect(layout.rows, lessThanOrEqualTo(10), reason: level.letters);
        }
      });
    });
  }

  test('una palabra sin letras en común no se puede colocar', () {
    expect(() => CrosswordLayout.build(['SOL', 'PAN']), throwsStateError);
  });
}

Iterable<String> _allRuns(CrosswordLayout layout) sync* {
  for (var row = 0; row < layout.rows; row++) {
    yield* _runs([
      for (var col = 0; col < layout.cols; col++) layout.letters[(row, col)],
    ]);
  }
  for (var col = 0; col < layout.cols; col++) {
    yield* _runs([
      for (var row = 0; row < layout.rows; row++) layout.letters[(row, col)],
    ]);
  }
}

/// Sequences of two or more consecutive letters in a line of the grid.
Iterable<String> _runs(List<String?> line) sync* {
  final buffer = StringBuffer();
  for (final cell in [...line, null]) {
    if (cell != null) {
      buffer.write(cell);
    } else {
      if (buffer.length > 1) yield buffer.toString();
      buffer.clear();
    }
  }
}
