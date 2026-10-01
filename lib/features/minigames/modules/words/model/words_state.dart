import 'package:memory_companion/features/minigames/core/minigame_level.dart';

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

/// Share of right answers that passes a level, on the first levels.
const wordsPassRatio = 0.8;

/// How the game gets harder, level after level, with no top: the list
/// grows until [wordsMaxListSize]; from then on the list stays up for less
/// time and the bar to pass rises.
class WordsDifficulty {
  const WordsDifficulty({
    required this.level,
    required this.listSize,
    required this.studyMsPerWord,
    required this.passRatio,
  });

  factory WordsDifficulty.forLevel(int level) {
    final safe = level < 1 ? 1 : level;
    final pastMax = safe - 5;
    return WordsDifficulty(
      level: safe,
      listSize: levelRamp(
        safe,
        start: wordsStartListSize,
        step: wordsListSizeStep,
        max: wordsMaxListSize,
      ),
      studyMsPerWord: pastMax <= 0
          ? 2000
          : (2000 - 100 * pastMax).clamp(700, 2000),
      passRatio: safe >= 30
          ? 0.9
          : safe >= 15
          ? 0.85
          : wordsPassRatio,
    );
  }

  final int level;
  final int listSize;
  final int studyMsPerWord;
  final double passRatio;

  /// How long the list stays up if the player does not tap "ready" first.
  Duration get studyDuration =>
      Duration(milliseconds: studyMsPerWord * listSize);
}

/// How long a list stays up on the first levels.
Duration wordsStudyDuration(int listSize) =>
    Duration(milliseconds: 2000 * listSize);

class WordsState {
  const WordsState({
    required this.phase,
    required this.difficulty,
    this.studied = const [],
    this.probes = const [],
    this.answered = 0,
    this.correct = 0,
    this.lastAnswerCorrect = false,
  });

  WordsState.intro({int level = 1})
    : this(
        phase: WordsPhase.intro,
        difficulty: WordsDifficulty.forLevel(level),
      );

  final WordsPhase phase;
  final WordsDifficulty difficulty;

  int get level => difficulty.level;

  /// Words to remember this round.
  int get listSize => difficulty.listSize;

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
      probes.isNotEmpty && correct / probes.length >= difficulty.passRatio;

  int get score => correct * 10;

  /// The list size of the level after this one.
  int get nextListSize => WordsDifficulty.forLevel(level + 1).listSize;

  WordsState copyWith({
    WordsPhase? phase,
    int? answered,
    int? correct,
    bool? lastAnswerCorrect,
  }) {
    return WordsState(
      phase: phase ?? this.phase,
      difficulty: difficulty,
      studied: studied,
      probes: probes,
      answered: answered ?? this.answered,
      correct: correct ?? this.correct,
      lastAnswerCorrect: lastAnswerCorrect ?? this.lastAnswerCorrect,
    );
  }
}
