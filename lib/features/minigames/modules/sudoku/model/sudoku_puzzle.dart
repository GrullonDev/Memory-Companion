import 'dart:math';

/// The shape of a sudoku: a [size] × [size] grid split into boxes of
/// [boxRows] × [boxCols]. Every row, column and box holds 1..[size] once.
class SudokuShape {
  const SudokuShape(this.size, this.boxRows, this.boxCols)
    : assert(boxRows * boxCols == size);

  static const mini = SudokuShape(4, 2, 2);
  static const midi = SudokuShape(6, 2, 3);
  static const classic = SudokuShape(9, 3, 3);

  final int size;
  final int boxRows;
  final int boxCols;

  int get cellCount => size * size;

  int rowOf(int index) => index ~/ size;
  int colOf(int index) => index % size;
  int boxOf(int index) =>
      (rowOf(index) ~/ boxRows) * (size ~/ boxCols) + colOf(index) ~/ boxCols;

  @override
  bool operator ==(Object other) =>
      other is SudokuShape &&
      other.size == size &&
      other.boxRows == boxRows &&
      other.boxCols == boxCols;

  @override
  int get hashCode => Object.hash(size, boxRows, boxCols);
}

/// A dealt puzzle: the full [solution] and the [givens] shown at the start
/// (0 marks an empty cell). The givens always have exactly one solution.
class SudokuPuzzle {
  const SudokuPuzzle({
    required this.shape,
    required this.solution,
    required this.givens,
  });

  final SudokuShape shape;
  final List<int> solution;
  final List<int> givens;

  int get holes => givens.where((v) => v == 0).length;

  /// Deals a puzzle with up to [holes] empty cells.
  ///
  /// Fills a random complete grid, then empties cells in random order,
  /// putting back any whose removal would allow a second solution. A grid
  /// may run out of removable cells before [holes]; the puzzle is then as
  /// hard as a unique puzzle from that grid gets.
  factory SudokuPuzzle.generate({
    required SudokuShape shape,
    required int holes,
    required Random random,
  }) {
    final solution = List<int>.filled(shape.cellCount, 0);
    _Solver(shape, solution, random: random).fill();

    final givens = [...solution];
    final order = List<int>.generate(shape.cellCount, (i) => i)
      ..shuffle(random);
    var removed = 0;
    for (final index in order) {
      if (removed >= holes) break;
      final kept = givens[index];
      givens[index] = 0;
      if (_Solver(shape, [...givens]).countSolutions(limit: 2) == 1) {
        removed++;
      } else {
        givens[index] = kept;
      }
    }
    return SudokuPuzzle(shape: shape, solution: solution, givens: givens);
  }
}

/// Backtracking over bitmasks, always branching on the empty cell with the
/// fewest candidates: fast enough for a 9 × 9 on the UI thread.
class _Solver {
  _Solver(this.shape, this.cells, {this.random})
    : _rows = List.filled(shape.size, 0),
      _cols = List.filled(shape.size, 0),
      _boxes = List.filled(shape.size, 0) {
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != 0) _place(i, cells[i]);
    }
  }

  final SudokuShape shape;
  final List<int> cells;
  final Random? random;
  final List<int> _rows;
  final List<int> _cols;
  final List<int> _boxes;

  int get _all => (1 << (shape.size + 1)) - 2;

  void _place(int i, int value) {
    final bit = 1 << value;
    _rows[shape.rowOf(i)] |= bit;
    _cols[shape.colOf(i)] |= bit;
    _boxes[shape.boxOf(i)] |= bit;
  }

  void _clear(int i, int value) {
    final bit = ~(1 << value);
    _rows[shape.rowOf(i)] &= bit;
    _cols[shape.colOf(i)] &= bit;
    _boxes[shape.boxOf(i)] &= bit;
  }

  int _candidates(int i) =>
      _all &
      ~(_rows[shape.rowOf(i)] | _cols[shape.colOf(i)] | _boxes[shape.boxOf(i)]);

  /// The empty cell with the fewest candidates, or -1 when full.
  int _mostConstrained() {
    var best = -1;
    var bestCount = 1 << 30;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != 0) continue;
      final count = _bitCount(_candidates(i));
      if (count < bestCount) {
        best = i;
        bestCount = count;
        if (count <= 1) break;
      }
    }
    return best;
  }

  List<int> _values(int mask) => [
    for (var v = 1; v <= shape.size; v++)
      if (mask & (1 << v) != 0) v,
  ];

  /// Completes [cells] with random values. The grid must be solvable.
  bool fill() {
    final i = _mostConstrained();
    if (i < 0) return true;
    final values = _values(_candidates(i))..shuffle(random);
    for (final v in values) {
      cells[i] = v;
      _place(i, v);
      if (fill()) return true;
      _clear(i, v);
      cells[i] = 0;
    }
    return false;
  }

  /// Solutions of [cells], counting no further than [limit].
  int countSolutions({required int limit}) {
    final i = _mostConstrained();
    if (i < 0) return 1;
    var found = 0;
    for (final v in _values(_candidates(i))) {
      cells[i] = v;
      _place(i, v);
      found += countSolutions(limit: limit - found);
      _clear(i, v);
      cells[i] = 0;
      if (found >= limit) break;
    }
    return found;
  }

  static int _bitCount(int mask) {
    var count = 0;
    for (var m = mask; m != 0; m &= m - 1) {
      count++;
    }
    return count;
  }
}
