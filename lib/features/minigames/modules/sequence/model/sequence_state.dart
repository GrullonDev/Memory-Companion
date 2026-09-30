import 'package:memory_companion/features/minigames/core/minigame_level.dart';

enum SequencePhase { intro, showing, input, feedback, finished }

/// Misses in a row that end the game.
const sequenceMaxMisses = 2;

/// How long the right/wrong feedback stays up.
const sequenceFeedbackDuration = Duration(milliseconds: 900);

/// How hard the sequence game is at a level: more pads, longer sequences
/// to start from and to reach, and quicker flashes, with no top.
class SequenceDifficulty {
  const SequenceDifficulty({
    required this.level,
    required this.pads,
    required this.startLength,
    required this.targetLength,
    required this.flashMs,
  });

  factory SequenceDifficulty.forLevel(int level) {
    final l = level < 1 ? 1 : level;
    final start = levelRamp(l, start: 3, every: 3, max: 9);
    return SequenceDifficulty(
      level: l,
      pads: l < 6
          ? 4
          : l < 12
          ? 6
          : 9,
      startLength: start,
      targetLength: start + 3,
      flashMs: levelRamp(l, start: 700, step: -25, max: 250),
    );
  }

  final int level;

  /// Pads on the board: 4, then 6, then 9.
  final int pads;
  final int startLength;

  /// Repeating a sequence this long wins the round.
  final int targetLength;

  /// How long each pad stays lit; the pause between two is half of it.
  final int flashMs;

  Duration get flash => Duration(milliseconds: flashMs);
  Duration get gap => Duration(milliseconds: flashMs ~/ 2);
}

class SequenceState {
  const SequenceState({
    required this.phase,
    required this.difficulty,
    this.sequence = const [],
    this.lit,
    this.entered = 0,
    this.trials = 0,
    this.correct = 0,
    this.misses = 0,
    this.bestLength = 0,
    this.score = 0,
    this.lastCorrect = false,
  });

  SequenceState.intro({int level = 1})
    : this(
        phase: SequencePhase.intro,
        difficulty: SequenceDifficulty.forLevel(level),
      );

  final SequencePhase phase;
  final SequenceDifficulty difficulty;

  /// Pads to repeat, in order.
  final List<int> sequence;

  /// The pad lit right now, while showing or as the player taps.
  final int? lit;

  /// Pads of [sequence] tapped right so far.
  final int entered;

  /// Sequences answered this round.
  final int trials;
  final int correct;

  /// Misses in a row.
  final int misses;
  final int bestLength;
  final int score;
  final bool lastCorrect;

  int get level => difficulty.level;
  int get length => sequence.length;
  bool get won => bestLength >= difficulty.targetLength;

  SequenceState copyWith({
    SequencePhase? phase,
    List<int>? sequence,
    int? Function()? lit,
    int? entered,
    int? trials,
    int? correct,
    int? misses,
    int? bestLength,
    int? score,
    bool? lastCorrect,
  }) {
    return SequenceState(
      phase: phase ?? this.phase,
      difficulty: difficulty,
      sequence: sequence ?? this.sequence,
      lit: lit == null ? this.lit : lit(),
      entered: entered ?? this.entered,
      trials: trials ?? this.trials,
      correct: correct ?? this.correct,
      misses: misses ?? this.misses,
      bestLength: bestLength ?? this.bestLength,
      score: score ?? this.score,
      lastCorrect: lastCorrect ?? this.lastCorrect,
    );
  }
}
