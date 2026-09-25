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

/// How long a number of [span] digits stays on screen.
Duration digitsShowDuration(int span) =>
    Duration(milliseconds: 1000 + 500 * span);

/// How long the right/wrong feedback stays up before the next number.
const digitsFeedbackDuration = Duration(milliseconds: 1400);

class DigitsState {
  const DigitsState({
    required this.phase,
    this.mode = DigitsMode.forward,
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
  bool get won => bestSpan >= mode.targetSpan;

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
