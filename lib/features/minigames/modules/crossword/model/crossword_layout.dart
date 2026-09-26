/// A grid position: `(row, col)`.
typedef GridPos = (int, int);

enum CrosswordDirection {
  across,
  down;

  CrosswordDirection get other => this == across ? down : across;
}

/// One word on the grid, from its first letter.
class PlacedWord {
  const PlacedWord(this.word, this.row, this.col, this.direction);

  final String word;
  final int row;
  final int col;
  final CrosswordDirection direction;

  List<GridPos> get cells => [
    for (var i = 0; i < word.length; i++)
      direction == CrosswordDirection.across ? (row, col + i) : (row + i, col),
  ];

  PlacedWord shifted(int rows, int cols) =>
      PlacedWord(word, row + rows, col + cols, direction);
}

/// Words laid out as a crossword: every word crosses at least one other,
/// and words never touch except where they cross.
///
/// Built from a plain word list by [CrosswordLayout.build], so a level is
/// only its letters and its words — no hand-drawn grids to keep in sync.
class CrosswordLayout {
  const CrosswordLayout._(this.words, this.rows, this.cols, this.letters);

  final List<PlacedWord> words;
  final int rows;
  final int cols;

  /// The letter at each used cell.
  final Map<GridPos, String> letters;

  bool contains(String word) => words.any((w) => w.word == word);

  PlacedWord wordOf(String word) => words.firstWhere((w) => w.word == word);

  /// Lays out [words], each one crossing a word already placed at the spot
  /// that keeps the grid most compact.
  ///
  /// Greedy placement can paint itself into a corner, so it is tried from
  /// every word as the first one down, and the most compact grid wins.
  ///
  /// Deterministic: the same list always gives the same grid. Throws
  /// [StateError] if no start lays out every word; the level tests make
  /// sure no shipped level does.
  factory CrosswordLayout.build(List<String> words) {
    final sorted = [...words]
      ..sort((a, b) {
        final byLength = b.length.compareTo(a.length);
        return byLength != 0 ? byLength : a.compareTo(b);
      });

    CrosswordLayout? best;
    for (final first in sorted) {
      final layout = _layOut(first, [...sorted]..remove(first));
      if (layout == null) continue;
      if (best == null || layout.rows * layout.cols < best.rows * best.cols) {
        best = layout;
      }
    }
    if (best == null) throw StateError('Cannot lay out $sorted');
    return best;
  }

  static CrosswordLayout? _layOut(String first, List<String> rest) {
    final grid = _Grid()
      ..place(PlacedWord(first, 0, 0, CrosswordDirection.across));

    // A word that fits nowhere yet may fit once a later word is down.
    final pending = rest;
    var progress = true;
    while (pending.isNotEmpty && progress) {
      progress = false;
      for (final word in [...pending]) {
        final placement = grid.bestPlacementOf(word);
        if (placement == null) continue;
        grid.place(placement);
        pending.remove(word);
        progress = true;
      }
    }
    return pending.isEmpty ? grid.normalized() : null;
  }
}

class _Grid {
  final words = <PlacedWord>[];
  final letters = <GridPos, String>{};

  /// Direction of the word(s) through each cell, to reject a new word
  /// running along an existing one.
  final directions = <GridPos, Set<CrosswordDirection>>{};

  void place(PlacedWord word) {
    words.add(word);
    final cells = word.cells;
    for (var i = 0; i < cells.length; i++) {
      letters[cells[i]] = word.word[i];
      (directions[cells[i]] ??= {}).add(word.direction);
    }
  }

  PlacedWord? bestPlacementOf(String word) {
    PlacedWord? best;
    var bestScore = 0;
    for (final placed in words) {
      for (var i = 0; i < word.length; i++) {
        for (var j = 0; j < placed.word.length; j++) {
          if (word[i] != placed.word[j]) continue;
          final (row, col) = placed.cells[j];
          final direction = placed.direction.other;
          final candidate = direction == CrosswordDirection.across
              ? PlacedWord(word, row, col - i, direction)
              : PlacedWord(word, row - i, col, direction);
          final crossings = _crossingsOf(candidate);
          if (crossings == null) continue;
          // Smaller grids first; among equals, the one that crosses more.
          final score = _areaWith(candidate) * 10 - crossings;
          if (best == null || score < bestScore) {
            best = candidate;
            bestScore = score;
          }
        }
      }
    }
    return best;
  }

  /// How many letters [candidate] shares with the grid, or null if it
  /// cannot go there.
  int? _crossingsOf(PlacedWord candidate) {
    final across = candidate.direction == CrosswordDirection.across;
    final cells = candidate.cells;
    final (firstRow, firstCol) = cells.first;
    final (lastRow, lastCol) = cells.last;
    final before = across ? (firstRow, firstCol - 1) : (firstRow - 1, firstCol);
    final after = across ? (lastRow, lastCol + 1) : (lastRow + 1, lastCol);
    if (letters.containsKey(before) || letters.containsKey(after)) return null;

    var crossings = 0;
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      final existing = letters[cell];
      if (existing != null) {
        if (existing != candidate.word[i]) return null;
        if (directions[cell]!.contains(candidate.direction)) return null;
        crossings++;
      } else {
        // A new letter must not touch a neighbouring word from the side.
        final (row, col) = cell;
        final sides = across
            ? [(row - 1, col), (row + 1, col)]
            : [(row, col - 1), (row, col + 1)];
        if (sides.any(letters.containsKey)) return null;
      }
    }
    return crossings == 0 ? null : crossings;
  }

  int _areaWith(PlacedWord candidate) {
    final cells = [...letters.keys, ...candidate.cells];
    final rows = cells.map((c) => c.$1);
    final cols = cells.map((c) => c.$2);
    final height = rows.reduce(_max) - rows.reduce(_min) + 1;
    final width = cols.reduce(_max) - cols.reduce(_min) + 1;
    return height * width;
  }

  /// Moves the grid so its top-left used cell is `(0, 0)`.
  CrosswordLayout normalized() {
    final minRow = letters.keys.map((c) => c.$1).reduce(_min);
    final minCol = letters.keys.map((c) => c.$2).reduce(_min);
    final shifted = [for (final w in words) w.shifted(-minRow, -minCol)];
    final shiftedLetters = {
      for (final MapEntry(key: (row, col), :value) in letters.entries)
        (row - minRow, col - minCol): value,
    };
    final rows = shiftedLetters.keys.map((c) => c.$1).reduce(_max) + 1;
    final cols = shiftedLetters.keys.map((c) => c.$2).reduce(_max) + 1;
    return CrosswordLayout._(shifted, rows, cols, shiftedLetters);
  }
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;
