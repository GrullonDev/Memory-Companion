import 'dart:math';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';

enum MathPhase { intro, playing, feedback, finished }

enum MathOp {
  add('+'),
  subtract('−'),
  multiply('×'),
  divide('÷');

  const MathOp(this.symbol);

  final String symbol;
}

/// Problems per round.
const mathProblemsPerRound = 10;

/// Right answers that pass a round.
const mathPassCount = 8;

/// How long the right/wrong feedback stays up.
const mathFeedbackDuration = Duration(milliseconds: 700);

/// How hard the arithmetic is at a level: new operations every few levels,
/// bigger numbers every level and less time to answer, with no top.
class MathDifficulty {
  const MathDifficulty({
    required this.level,
    required this.ops,
    required this.maxAddend,
    required this.maxFactor,
    required this.timeLimitMs,
  });

  factory MathDifficulty.forLevel(int level) {
    final l = level < 1 ? 1 : level;
    return MathDifficulty(
      level: l,
      ops: [
        MathOp.add,
        if (l >= 4) MathOp.subtract,
        if (l >= 7) MathOp.multiply,
        if (l >= 11) MathOp.divide,
      ],
      maxAddend: levelRamp(l, start: 10, step: 5, max: 999),
      maxFactor: levelRamp(l - 6, start: 5, every: 2, max: 30),
      timeLimitMs: levelRamp(l, start: 10000, step: -300, max: 3000),
    );
  }

  final int level;
  final List<MathOp> ops;

  /// Largest number in a sum or subtraction.
  final int maxAddend;

  /// Largest factor in a product or division.
  final int maxFactor;
  final int timeLimitMs;

  Duration get timeLimit => Duration(milliseconds: timeLimitMs);
}

/// One problem and four choices, the answer among them.
class MathProblem {
  const MathProblem(this.a, this.op, this.b, this.answer, this.choices);

  /// Deals a problem with whole, non-negative operands and answer.
  factory MathProblem.deal(MathDifficulty difficulty, Random random) {
    final op = difficulty.ops[random.nextInt(difficulty.ops.length)];
    int roll(int max) => 1 + random.nextInt(max < 1 ? 1 : max);
    int a, b, answer;
    switch (op) {
      case MathOp.add:
        a = roll(difficulty.maxAddend);
        b = roll(difficulty.maxAddend);
        answer = a + b;
      case MathOp.subtract:
        final x = roll(difficulty.maxAddend);
        final y = roll(difficulty.maxAddend);
        a = max(x, y);
        b = min(x, y);
        answer = a - b;
      case MathOp.multiply:
        a = roll(difficulty.maxFactor);
        b = roll(difficulty.maxFactor);
        answer = a * b;
      case MathOp.divide:
        b = roll(difficulty.maxFactor);
        answer = roll(difficulty.maxFactor);
        a = b * answer;
    }

    // Near misses make better distractors than random numbers: they are
    // what a slip of the mind actually produces.
    final spread = max(3, answer ~/ 10);
    final choices = <int>{answer};
    while (choices.length < 4) {
      final offset = 1 + random.nextInt(spread);
      final candidate = random.nextBool() ? answer + offset : answer - offset;
      if (candidate >= 0) choices.add(candidate);
    }
    return MathProblem(a, op, b, answer, choices.toList()..shuffle(random));
  }

  final int a;
  final MathOp op;
  final int b;
  final int answer;
  final List<int> choices;

  String get text => '$a ${op.symbol} $b';
}

class MathState {
  const MathState({
    required this.phase,
    required this.difficulty,
    this.problems = const [],
    this.index = 0,
    this.correct = 0,
    this.lastCorrect = false,
    this.picked,
  });

  MathState.intro({int level = 1})
    : this(phase: MathPhase.intro, difficulty: MathDifficulty.forLevel(level));

  final MathPhase phase;
  final MathDifficulty difficulty;
  final List<MathProblem> problems;

  /// The problem on screen.
  final int index;
  final int correct;
  final bool lastCorrect;

  /// The choice tapped for the current problem; null if time ran out.
  final int? picked;

  int get level => difficulty.level;
  MathProblem? get current => index < problems.length ? problems[index] : null;
  int get answered => phase == MathPhase.feedback ? index + 1 : index;
  int get errors => answered - correct;
  bool get won => correct >= mathPassCount;
  int get score => correct * 10 * (1 + difficulty.ops.length);

  MathState copyWith({
    MathPhase? phase,
    int? index,
    int? correct,
    bool? lastCorrect,
    int? Function()? picked,
  }) {
    return MathState(
      phase: phase ?? this.phase,
      difficulty: difficulty,
      problems: problems,
      index: index ?? this.index,
      correct: correct ?? this.correct,
      lastCorrect: lastCorrect ?? this.lastCorrect,
      picked: picked == null ? this.picked : picked(),
    );
  }
}
