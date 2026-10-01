import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/words/model/word_bank.dart';
import 'package:memory_companion/features/minigames/modules/words/model/words_state.dart';
import 'package:memory_companion/features/minigames/modules/words/words_game_module.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs the word-recognition game: study a list, then sort a shuffled mix
/// of those words and new ones into "was on the list" or "was not".
///
/// Half the probes are new words, so always answering "yes" (or "no")
/// scores 50% and never passes a level. One round is one stats row.
class WordsController extends Notifier<WordsState> {
  WordsController(this.languageCode);

  /// Language the words are dealt in.
  final String languageCode;

  Timer? _studyTimer;
  late DateTime _startedAt;

  static const _game = WordsGameModule();

  @override
  WordsState build() {
    ref.onDispose(() => _studyTimer?.cancel());
    // Keeps the ladder level loading while the intro is on screen.
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return WordsState.intro(level: ref.read(minigameLevelProvider(_game)));
  }

  /// Deals a round at [level]: the player's ladder level by default, or the
  /// level just played when retrying.
  void start({int? level}) {
    final ladder = ref.read(minigameLevelProvider(_game));
    final difficulty = WordsDifficulty.forLevel(
      level ?? max(ladder, state.phase == WordsPhase.intro ? 1 : state.level),
    );
    final size = difficulty.listSize;
    final random = ref.read(minigameRandomProvider);
    final pool = [...WordBank.forLanguage(languageCode)]..shuffle(random);
    final studied = pool.take(size).toList();
    final probes = [...studied, ...pool.skip(size).take(size)]..shuffle(random);

    _startedAt = ref.read(statsClockProvider)();
    state = WordsState(
      phase: WordsPhase.study,
      difficulty: difficulty,
      studied: studied,
      probes: probes,
    );
    _studyTimer?.cancel();
    _studyTimer = Timer(difficulty.studyDuration, finishStudy);
  }

  /// Plays the next level: a longer list, or less time to study it.
  void nextLevel() => start(level: state.level + 1);

  /// Hides the list and starts asking.
  void finishStudy() {
    if (state.phase != WordsPhase.study) return;
    _studyTimer?.cancel();
    state = state.copyWith(phase: WordsPhase.test);
  }

  /// The player's verdict on the current probe.
  void answer({required bool wasOnList}) {
    final probe = state.currentProbe;
    if (probe == null) return;
    final correct = state.studied.contains(probe) == wasOnList;
    state = state.copyWith(
      answered: state.answered + 1,
      correct: state.correct + (correct ? 1 : 0),
      lastAnswerCorrect: correct,
    );
    if (state.answered == state.probes.length) _finish();
  }

  void _finish() {
    state = state.copyWith(phase: WordsPhase.finished);
    final seconds = ref
        .read(statsClockProvider)()
        .difference(_startedAt)
        .inSeconds;
    final reporter = ref.read(minigameResultReporterProvider);
    unawaited(
      reporter.report(
        _game,
        MinigameResult(
          itemCount: state.probes.length,
          itemsSolved: state.correct,
          attempts: state.answered,
          errors: state.errors,
          secondsElapsed: max(0, seconds),
          won: state.won,
          score: state.score,
        ),
      ),
    );
  }
}

/// One game per word language, discarded when the player leaves it.
final wordsControllerProvider = NotifierProvider.autoDispose
    .family<WordsController, WordsState, String>(WordsController.new);
