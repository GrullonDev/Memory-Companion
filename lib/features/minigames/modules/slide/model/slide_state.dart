import 'dart:math';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';

enum SlidePhase { intro, playing, finished }

/// How hard the sliding puzzle is at a level: a bigger board every few
/// levels and a deeper shuffle every level, with no top worth reaching.
class SlideDifficulty {
  const SlideDifficulty({
    required this.level,
    required this.size,
    required this.shuffleMoves,
  });

  factory SlideDifficulty.forLevel(int level) {
    final l = level < 1 ? 1 : level;
    if (l < 7) {
      return SlideDifficulty(
        level: l,
        size: 3,
        shuffleMoves: levelRamp(l, start: 10, step: 6, max: 60),
      );
    }
    if (l < 16) {
      return SlideDifficulty(
        level: l,
        size: 4,
        shuffleMoves: levelRamp(l - 6, start: 30, step: 10, max: 150),
      );
    }
    return SlideDifficulty(
      level: l,
      size: 5,
      shuffleMoves: levelRamp(l - 15, start: 60, step: 12, max: 600),
    );
  }

  final int level;

  /// Tiles per side.
  final int size;

  /// Random moves applied to the solved board.
  final int shuffleMoves;
}

/// A board: tile numbers row by row, 0 for the gap. Solved is 1..n², 0 last.
class SlideBoard {
  const SlideBoard(this.size, this.tiles);

  factory SlideBoard.solved(int size) =>
      SlideBoard(size, [for (var i = 1; i < size * size; i++) i, 0]);

  /// The solved board after [moves] random slides, never undoing the one
  /// before — so it is always solvable, and never handed over already
  /// solved.
  factory SlideBoard.shuffled(int size, int moves, Random random) {
    var board = SlideBoard.solved(size);
    int? previousGap;
    var done = 0;
    while (done < moves || board.solved) {
      final options = board.movable().where((i) => i != previousGap).toList();
      final tile = options[random.nextInt(options.length)];
      previousGap = board.gap;
      board = board.slide(tile)!;
      done++;
    }
    return board;
  }

  final int size;
  final List<int> tiles;

  int get gap => tiles.indexOf(0);

  bool get solved {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  /// Indexes of the tiles next to the gap.
  List<int> movable() {
    final g = gap;
    final row = g ~/ size;
    final col = g % size;
    return [
      if (row > 0) g - size,
      if (row < size - 1) g + size,
      if (col > 0) g - 1,
      if (col < size - 1) g + 1,
    ];
  }

  /// The board after sliding the tile at [index] into the gap, or null if
  /// that tile does not touch the gap.
  SlideBoard? slide(int index) {
    if (!movable().contains(index)) return null;
    final next = [...tiles];
    next[gap] = next[index];
    next[index] = 0;
    return SlideBoard(size, next);
  }
}

class SlideState {
  const SlideState({
    required this.phase,
    required this.difficulty,
    this.board,
    this.moves = 0,
  });

  SlideState.intro({int level = 1})
    : this(
        phase: SlidePhase.intro,
        difficulty: SlideDifficulty.forLevel(level),
      );

  final SlidePhase phase;
  final SlideDifficulty difficulty;
  final SlideBoard? board;
  final int moves;

  int get level => difficulty.level;
  bool get won => board?.solved ?? false;

  /// Better the closer [moves] gets to the shuffle depth.
  int get score {
    final tiles = difficulty.size * difficulty.size;
    final extra = moves - difficulty.shuffleMoves;
    final points = tiles * 40 - (extra > 0 ? extra * 2 : 0);
    return points < tiles * 5 ? tiles * 5 : points;
  }

  SlideState copyWith({SlidePhase? phase, SlideBoard? board, int? moves}) {
    return SlideState(
      phase: phase ?? this.phase,
      difficulty: difficulty,
      board: board ?? this.board,
      moves: moves ?? this.moves,
    );
  }
}
