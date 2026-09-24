import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_layout.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_levels.dart';

/// What happened to the last word the player entered.
enum CrosswordFeedback { found, repeated, invalid }

class CrosswordState {
  const CrosswordState({
    required this.levelNumber,
    required this.level,
    required this.layout,
    required this.wheel,
    this.found = const {},
    this.hinted = const {},
    this.attempts = 0,
    this.errors = 0,
    this.hintsUsed = 0,
    this.feedback,
    this.feedbackWord = '',
  });

  /// 1-based, and keeps counting after the puzzles start over.
  final int levelNumber;
  final CrosswordLevel level;
  final CrosswordLayout layout;

  /// The level's letters in the order the wheel shows them.
  final List<String> wheel;

  /// Words already on the grid.
  final Set<String> found;

  /// Cells a hint has revealed.
  final Set<GridPos> hinted;

  /// Words entered, plus words a hint completed.
  final int attempts;

  /// Words entered that are not in the puzzle.
  final int errors;
  final int hintsUsed;

  final CrosswordFeedback? feedback;

  /// The word [feedback] is about.
  final String feedbackWord;

  bool get solved => found.length == layout.words.length;

  /// Cells shown on the grid: every cell of a found word, and hinted ones.
  Set<GridPos> get revealed => {
    ...hinted,
    for (final word in layout.words)
      if (found.contains(word.word)) ...word.cells,
  };

  /// Letters of every word, less a letter per hint. Never below zero.
  int get score {
    final letters = layout.words.fold(0, (sum, w) => sum + w.word.length);
    final points = (letters - hintsUsed) * 10;
    return points < 0 ? 0 : points;
  }

  CrosswordState copyWith({
    List<String>? wheel,
    Set<String>? found,
    Set<GridPos>? hinted,
    int? attempts,
    int? errors,
    int? hintsUsed,
    CrosswordFeedback? feedback,
    String? feedbackWord,
  }) {
    return CrosswordState(
      levelNumber: levelNumber,
      level: level,
      layout: layout,
      wheel: wheel ?? this.wheel,
      found: found ?? this.found,
      hinted: hinted ?? this.hinted,
      attempts: attempts ?? this.attempts,
      errors: errors ?? this.errors,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      feedback: feedback ?? this.feedback,
      feedbackWord: feedbackWord ?? this.feedbackWord,
    );
  }
}
