import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/model/sudoku_puzzle.dart';

enum SudokuPhase { intro, playing, finished }

/// How hard the sudoku is at a level. It never stops rising: a 4 × 4 to
/// learn the rules, a 6 × 6, then the classic 9 × 9 with fewer and fewer
/// clues and, once the clues bottom out, fewer mistakes allowed.
class SudokuDifficulty {
  const SudokuDifficulty({
    required this.level,
    required this.shape,
    required this.holes,
    required this.maxMistakes,
    required this.freeHints,
  });

  factory SudokuDifficulty.forLevel(int level) {
    final l = level < 1 ? 1 : level;
    if (l <= 3) {
      return SudokuDifficulty(
        level: l,
        shape: SudokuShape.mini,
        holes: levelRamp(l, start: 6, step: 2, max: 10),
        maxMistakes: 3,
        freeHints: 1,
      );
    }
    if (l <= 8) {
      return SudokuDifficulty(
        level: l,
        shape: SudokuShape.midi,
        holes: levelRamp(l - 3, start: 14, step: 2, max: 22),
        maxMistakes: 3,
        freeHints: 2,
      );
    }
    final classic = l - 8;
    return SudokuDifficulty(
      level: l,
      shape: SudokuShape.classic,
      holes: levelRamp(classic, start: 36, step: 2, max: sudokuMaxHoles),
      // After the clues bottom out (level 19), one mistake fewer every ten
      // levels, down to a single one.
      maxMistakes: levelRamp(
        classic < 11 ? 1 : classic - 10,
        start: 3,
        step: -1,
        every: 10,
        max: 1,
      ),
      freeHints: classic < 11 ? 3 : 1,
    );
  }

  final int level;
  final SudokuShape shape;

  /// Empty cells to deal. The generator stops early if the grid cannot lose
  /// more clues and keep a single solution.
  final int holes;

  /// Wrong numbers allowed; one more ends the round.
  final int maxMistakes;

  /// Hints that cost nothing. Past them, a hint spends one from the store.
  final int freeHints;
}

/// Fewest clues a 9 × 9 is dealt with: 25, hard but still fair.
const sudokuMaxHoles = 56;

class SudokuState {
  const SudokuState({
    required this.phase,
    required this.difficulty,
    this.puzzle,
    this.cells = const [],
    this.selected,
    this.mistakes = 0,
    this.entries = 0,
    this.hintsUsed = 0,
    this.wrongCell,
  });

  SudokuState.intro({int level = 1})
    : this(
        phase: SudokuPhase.intro,
        difficulty: SudokuDifficulty.forLevel(level),
      );

  final SudokuPhase phase;
  final SudokuDifficulty difficulty;
  final SudokuPuzzle? puzzle;

  /// What the grid shows now: the givens plus every number placed.
  final List<int> cells;

  /// The cell the number pad writes to.
  final int? selected;
  final int mistakes;

  /// Numbers entered, right or wrong.
  final int entries;
  final int hintsUsed;

  /// The cell the last wrong number went to, to flash it.
  final int? wrongCell;

  int get level => difficulty.level;

  bool isGiven(int index) => puzzle!.givens[index] != 0;

  int get emptyCells => cells.where((v) => v == 0).length;
  int get holes => puzzle?.holes ?? 0;
  int get filled => holes - emptyCells;

  bool get solved => puzzle != null && emptyCells == 0;
  bool get won => solved && mistakes <= difficulty.maxMistakes;

  int get freeHintsLeft {
    final left = difficulty.freeHints - hintsUsed;
    return left < 0 ? 0 : left;
  }

  /// How many times each number is on the grid, to grey out finished ones.
  int countOf(int value) => cells.where((v) => v == value).length;

  int get score {
    final base = holes * 10 * difficulty.shape.size ~/ 3;
    final penalty = mistakes * 20 + hintsUsed * 15;
    return base - penalty < 0 ? 0 : base - penalty;
  }

  SudokuState copyWith({
    SudokuPhase? phase,
    List<int>? cells,
    int? Function()? selected,
    int? mistakes,
    int? entries,
    int? hintsUsed,
    int? Function()? wrongCell,
  }) {
    return SudokuState(
      phase: phase ?? this.phase,
      difficulty: difficulty,
      puzzle: puzzle,
      cells: cells ?? this.cells,
      selected: selected == null ? this.selected : selected(),
      mistakes: mistakes ?? this.mistakes,
      entries: entries ?? this.entries,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      wrongCell: wrongCell == null ? this.wrongCell : wrongCell(),
    );
  }
}
