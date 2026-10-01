import 'package:memory_companion/features/minigames/core/minigame_level.dart';

enum PatternPhase { intro, showing, input, finished }

/// How hard the pattern game is at a level: a bigger grid every few
/// levels, more cells lit, less time to look and fewer slips forgiven —
/// with no top.
class PatternDifficulty {
  const PatternDifficulty({
    required this.level,
    required this.gridSize,
    required this.litCount,
    required this.showMs,
    required this.allowedErrors,
  });

  factory PatternDifficulty.forLevel(int level) {
    final l = level < 1 ? 1 : level;
    final grid = levelRamp(l, start: 3, every: 4, max: 7);
    return PatternDifficulty(
      level: l,
      gridSize: grid,
      // Never more than half the grid: past that, remembering the dark
      // cells is easier than the lit ones.
      litCount: levelRamp(l, start: 3, every: 2, max: grid * grid ~/ 2),
      showMs: levelRamp(l, start: 2200, step: -50, max: 700),
      allowedErrors: l < 15
          ? 2
          : l < 30
          ? 1
          : 0,
    );
  }

  final int level;
  final int gridSize;
  final int litCount;
  final int showMs;

  /// Wrong taps forgiven; one more loses the round.
  final int allowedErrors;

  Duration get showDuration => Duration(milliseconds: showMs);
}

class PatternState {
  const PatternState({
    required this.phase,
    required this.difficulty,
    this.lit = const {},
    this.found = const {},
    this.wrong = const {},
  });

  PatternState.intro({int level = 1})
    : this(
        phase: PatternPhase.intro,
        difficulty: PatternDifficulty.forLevel(level),
      );

  final PatternPhase phase;
  final PatternDifficulty difficulty;

  /// Cells that lit up.
  final Set<int> lit;

  /// Lit cells the player found.
  final Set<int> found;

  /// Dark cells the player tapped.
  final Set<int> wrong;

  int get level => difficulty.level;
  int get errors => wrong.length;
  bool get lost => errors > difficulty.allowedErrors;
  bool get won => lit.isNotEmpty && found.length == lit.length && !lost;
  int get score {
    final points = found.length * 10 * difficulty.gridSize - errors * 15;
    return points < 0 ? 0 : points;
  }

  PatternState copyWith({
    PatternPhase? phase,
    Set<int>? found,
    Set<int>? wrong,
  }) {
    return PatternState(
      phase: phase ?? this.phase,
      difficulty: difficulty,
      lit: lit,
      found: found ?? this.found,
      wrong: wrong ?? this.wrong,
    );
  }
}
