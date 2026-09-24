enum WordsPhase {
  intro,

  /// The list to remember is on screen.
  study,

  /// One word at a time: was it on the list?
  test,
  finished,
}

/// Words on the first list.
const wordsStartListSize = 4;

/// Words added to the list per level passed.
const wordsListSizeStep = 2;
const wordsMaxListSize = 12;

/// Share of right answers that passes a level.
const wordsPassRatio = 0.8;

/// How long the list stays up if the player does not tap "ready" first.
Duration wordsStudyDuration(int listSize) =>
    Duration(milliseconds: 2000 * listSize);

class WordsState {
  const WordsState({
    required this.phase,
    required this.listSize,
    this.studied = const [],
    this.probes = const [],
    this.answered = 0,
    this.correct = 0,
    this.lastAnswerCorrect = false,
  });

  const WordsState.intro()
    : this(phase: WordsPhase.intro, listSize: wordsStartListSize);

  final WordsPhase phase;

  /// Words to remember this round.
  final int listSize;

  /// The list shown in the study phase.
  final List<String> studied;

  /// The studied words and as many new ones, shuffled.
  final List<String> probes;

  /// Probes answered so far; the next one is `probes[answered]`.
  final int answered;
  final int correct;

  /// Whether the previous probe was answered right. Meaningful once
  /// [answered] is above zero.
  final bool lastAnswerCorrect;

  String? get currentProbe =>
      phase == WordsPhase.test && answered < probes.length
      ? probes[answered]
      : null;

  int get errors => answered - correct;

  bool get won =>
      probes.isNotEmpty && correct / probes.length >= wordsPassRatio;

  int get score => correct * 10;

  /// The list size of the level after this one.
  int get nextListSize =>
      (listSize + wordsListSizeStep).clamp(wordsStartListSize, wordsMaxListSize);

  WordsState copyWith({
    WordsPhase? phase,
    int? answered,
    int? correct,
    bool? lastAnswerCorrect,
  }) {
    return WordsState(
      phase: phase ?? this.phase,
      listSize: listSize,
      studied: studied,
      probes: probes,
      answered: answered ?? this.answered,
      correct: correct ?? this.correct,
      lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
    );
  }
}
