import 'package:memory_companion/features/minigames/core/minigame_level.dart';

/// Which way the player types the number back.
enum DigitsMode {
  /// Same order it was shown: classic forward digit span.
  forward(variantId: null, startSpan: 3, targetSpan: 7),

  /// Last digit first: backward digit span, which also works the mind's
  /// ability to rearrange what it holds, so it starts and aims lower.
  reverse(variantId: 'reverse', startSpan: 2, targetSpan: 5);

  const DigitsMode({
    required this.variantId,
    required this.startSpan,
    required this.targetSpan,
  });

  /// Stats variant (`'digits'` or `'digits:reverse'`).
  final String? variantId;
  final int startSpan;

  /// Reaching this span wins the game: 7 forward is the typical adult span,
  /// and backward spans usually run about two digits shorter.
  final int targetSpan;

  String expectedAnswer(String sequence) => switch (this) {
    DigitsMode.forward => sequence,
    DigitsMode.reverse => sequence.split('').reversed.join(),
  };
}

enum DigitsPhase {
  /// Choosing a mode.
  intro,

  /// The number is on screen.
  showing,

  /// The number is hidden and the player types it.
  input,

  /// A beat to see whether the answer was right.
  feedback,
  finished,
}

/// Longest number ever dealt; getting it right ends the game as a win.
const digitsMaxSpan = 12;

/// Misses in a row that end the game.
const digitsMaxMisses = 2;

/// How long a number of [span] digits stays on screen on the first levels.
Duration digitsShowDuration(int span) => digitsShowDurationAt(span, level: 1);

/// How long a number of [span] digits stays on screen at [level]: 5 % less
/// per level, down to half.
Duration digitsShowDurationAt(int span, {required int level}) {
  final factor = (1 - 0.05 * (level - 1)).clamp(0.5, 1.0);
  return Duration(milliseconds: ((1000 + 500 * span) * factor).round());
}

/// Every third level starts one digit longer and asks for one more to win,
/// until the longest number [digitsMaxSpan]; the time to read keeps
/// shrinking after that (see [digitsShowDurationAt]).
int digitsStartSpanAt(DigitsMode mode, int level) =>
    levelRamp(level, start: mode.startSpan, every: 3, max: digitsMaxSpan - 4);

int digitsTargetSpanAt(DigitsMode mode, int level) =>
    levelRamp(level, start: mode.targetSpan, every: 3, max: digitsMaxSpan);

/// How long the right/wrong feedback stays up before the next number.
const digitsFeedbackDuration = Duration(milliseconds: 1400);

class DigitsState {
  const DigitsState({
    required this.phase,
    this.mode = DigitsMode.forward,
    this.level = 1,
    this.span = 0,
    this.sequence = '',
    this.input = '',
    this.trials = 0,
    this.correct = 0,
    this.misses = 0,
    this.bestSpan = 0,
    this.score = 0,
    this.lastCorrect = false,
  });

  const DigitsState.intro() : this(phase: DigitsPhase.intro);

  final DigitsPhase phase;
  final DigitsMode mode;

  /// Ladder level the game was dealt at.
  final int level;

  int get startSpan => digitsStartSpanAt(mode, level);
  int get targetSpan => digitsTargetSpanAt(mode, level);

  /// Digits in the current number.
  final int span;

  /// The number shown, as dealt.
  final String sequence;

  /// What the player has typed so far.
  final String input;

  /// Numbers answered this game.
  final int trials;
  final int correct;

  /// Misses in a row; reset by any correct answer.
  final int misses;

  /// Longest number recalled correctly this game.
  final int bestSpan;
  final int score;

  /// Whether the last answer was right. Meaningful from `feedback` on.
  final bool lastCorrect;

  String get expectedAnswer => mode.expectedAnswer(sequence);
  bool get canSubmit => phase == DigitsPhase.input && input.length == span;
  bool get won => bestSpan >= targetSpan;

  DigitsState copyWith({
    DigitsPhase? phase,
    int? span,
    String? sequence,
    String? input,
    int? trials,
    int? correct,
    int? misses,
    int? bestSpan,
    int? score,
    bool? lastCorrect,
  }) {
    return DigitsState(
      phase: phase ?? this.phase,
      mode: mode,
      level: level,
      span: span ?? this.span,
      sequence: sequence ?? this.sequence,
      input: input ?? this.input,
      trials: trials ?? this.trials,
      correct: correct ?? this.correct,
      misses: misses ?? this.misses,
      bestSpan: bestSpan ?? this.bestSpan,
      score: score ?? this.score,
      lastCorrect: lastCorrect ?? this.lastCorrect,
    );
  }
}
