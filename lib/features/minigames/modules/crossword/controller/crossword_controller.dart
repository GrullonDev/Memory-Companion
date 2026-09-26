import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_game_module.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_layout.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_levels.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_state.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs the word-wheel crossword: the player spells words from the wheel's
/// letters and each one found is written into the grid.
///
/// Progress needs no table of its own: the level to play is the number of
/// puzzles already won in this language, read from `game_stats`. A solved
/// puzzle is one stats row, so solving it is also what unlocks the next.
class CrosswordController extends AsyncNotifier<CrosswordState> {
  CrosswordController(this.languageCode);

  /// Language of the puzzles, and the stats variant they are kept under.
  final String languageCode;

  late DateTime _startedAt;

  Random get _random => ref.read(minigameRandomProvider);

  @override
  Future<CrosswordState> build() async {
    final fixed = ref.read(crosswordFixedLevelProvider);
    if (fixed != null) return _deal(fixed);
    const game = CrosswordGameModule();
    final cleared = await ref
        .read(statsRepositoryProvider)
        .countWins(game.statsKeyFor(languageCode));
    return _deal(cleared + 1);
  }

  CrosswordState _deal(int levelNumber) {
    final levels = CrosswordLevels.forLanguage(languageCode);
    final level = levels[(levelNumber - 1) % levels.length];
    _startedAt = ref.read(statsClockProvider)();
    return CrosswordState(
      levelNumber: levelNumber,
      level: level,
      layout: CrosswordLayout.build(level.words),
      wheel: level.letters.split('')..shuffle(_random),
    );
  }

  /// Deals the puzzle after the one just solved.
  void nextLevel() {
    final current = state.value;
    if (current == null || !current.solved) return;
    state = AsyncData(_deal(current.levelNumber + 1));
  }

  /// Rearranges the wheel, which often makes a hidden word jump out.
  void shuffle() {
    final current = state.value;
    if (current == null || current.solved) return;
    state = AsyncData(
      current.copyWith(wheel: [...current.wheel]..shuffle(_random)),
    );
  }

  /// Checks a word spelt on the wheel. Words shorter than
  /// [crosswordMinWordLength] are ignored: they are usually a slip.
  void submit(String entry) {
    final current = state.value;
    if (current == null || current.solved) return;
    final word = entry.toUpperCase();
    if (word.length < crosswordMinWordLength) return;

    if (current.found.contains(word)) {
      state = AsyncData(
        current.copyWith(
          feedback: CrosswordFeedback.repeated,
          feedbackWord: word,
        ),
      );
    } else if (current.layout.contains(word)) {
      _update(
        current.copyWith(
          found: {...current.found, word},
          attempts: current.attempts + 1,
          feedback: CrosswordFeedback.found,
          feedbackWord: word,
        ),
      );
    } else {
      state = AsyncData(
        current.copyWith(
          attempts: current.attempts + 1,
          errors: current.errors + 1,
          feedback: CrosswordFeedback.invalid,
          feedbackWord: word,
        ),
      );
    }
  }

  /// Reveals one hidden letter. A word whose letters are all revealed
  /// counts as found.
  void hint() {
    final current = state.value;
    if (current == null || current.solved) return;
    final revealed = current.revealed;
    final hidden = {
      for (final word in current.layout.words)
        for (final cell in word.cells)
          if (!revealed.contains(cell)) cell,
    }.toList();
    if (hidden.isEmpty) return;

    final hinted = {...current.hinted, hidden[_random.nextInt(hidden.length)]};
    final completed = [
      for (final word in current.layout.words)
        if (!current.found.contains(word.word) &&
            word.cells.every((c) => hinted.contains(c) || revealed.contains(c)))
          word.word,
    ];
    _update(
      current.copyWith(
        hinted: hinted,
        hintsUsed: current.hintsUsed + 1,
        found: {...current.found, ...completed},
        attempts: current.attempts + completed.length,
      ),
    );
  }

  void _update(CrosswordState next) {
    state = AsyncData(next);
    if (next.solved) _report(next);
  }

  void _report(CrosswordState solved) {
    final seconds = ref
        .read(statsClockProvider)()
        .difference(_startedAt)
        .inSeconds;
    final reporter = ref.read(minigameResultReporterProvider);
    unawaited(
      reporter.report(
        const CrosswordGameModule(),
        MinigameResult(
          variantId: languageCode,
          itemCount: solved.layout.words.length,
          itemsSolved: solved.found.length,
          attempts: solved.attempts,
          errors: solved.errors,
          hintsUsed: solved.hintsUsed,
          secondsElapsed: max(0, seconds),
          won: true,
          score: solved.score,
        ),
      ),
    );
  }
}

/// A puzzle to deal instead of the player's next one. Duels override it so
/// both sides solve the same puzzle, whatever their own progress.
final crosswordFixedLevelProvider = Provider<int?>((ref) => null);

/// One game per puzzle language, discarded when the player leaves it.
final crosswordControllerProvider = AsyncNotifierProvider.autoDispose
    .family<CrosswordController, CrosswordState, String>(
      CrosswordController.new,
    );
