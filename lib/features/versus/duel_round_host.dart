import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/daily_challenge/model/daily_seed.dart';
import 'package:memory_companion/features/game/board/board_screen.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/modules/crossword/controller/crossword_controller.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_screen.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_levels.dart';
import 'package:memory_companion/features/minigames/modules/digits/controller/digits_controller.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_screen.dart';
import 'package:memory_companion/features/minigames/modules/digits/model/digits_state.dart';
import 'package:memory_companion/features/minigames/modules/words/controller/words_controller.dart';
import 'package:memory_companion/features/minigames/modules/words/model/words_state.dart';
import 'package:memory_companion/features/minigames/modules/words/words_screen.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';

/// Plays one round of a duel on its game, dealt from the round's seed so
/// both sides get the same round.
///
/// The catalog's own screens are reused as they are: a [ProviderScope]
/// hands them the round's seeded randomness (and, for the crossword, a
/// fixed puzzle) and starts them straight away, skipping their intros.
class DuelRoundHost extends StatelessWidget {
  const DuelRoundHost({
    super.key,
    required this.duel,
    required this.round,
    required this.onProgress,
    required this.onFinished,
    required this.onExit,
  });

  final Duel duel;
  final int round;

  /// Where the player stands, whenever it changes: every pair matched or
  /// missed and every answer given comes with its [DuelEvent]. The round
  /// number is left for the caller to fill in.
  final ValueChanged<DuelProgress> onProgress;
  final ValueChanged<DuelScore> onFinished;
  final VoidCallback onExit;

  /// The crossword puzzle for [round], the same on both devices.
  int _crosswordLevel(String languageCode) =>
      duel.seedFor(round) % CrosswordLevels.forLanguage(languageCode).length +
      1;

  /// What changed between two board snapshots, as the rival should see it.
  ///
  /// A hit is a pair that just matched; a miss, two cards that just turned
  /// back face down — reported as they cover, in step with the board's own
  /// mismatch pause. The opening preview covers every card at once and is
  /// not a miss.
  static DuelProgress boardProgress(BoardState? previous, BoardState next) {
    final hits = <int>[];
    final covered = <int>[];
    if (previous != null && previous.cards.length == next.cards.length) {
      for (var i = 0; i < next.cards.length; i++) {
        final before = previous.cards[i];
        final after = next.cards[i];
        if (!before.isMatched && after.isMatched) hits.add(i);
        if (before.isFaceUp && !after.isFaceUp && !after.isMatched) {
          covered.add(i);
        }
      }
    }
    final isMiss =
        hits.isEmpty &&
        covered.length == 2 &&
        !(previous?.isPreviewing ?? true);
    return DuelProgress(
      round: 0,
      score: next.score,
      solved: next.matchedPairs,
      total: next.pairCount,
      event: hits.isNotEmpty
          ? DuelEvent.hit
          : (isMiss ? DuelEvent.miss : DuelEvent.none),
      cards: hits.isNotEmpty ? hits : (isMiss ? covered : const []),
      matched: [
        for (var i = 0; i < next.cards.length; i++)
          if (next.cards[i].isMatched) i,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (duel.game == DuelGame.memory) {
      return _BoardRound(
        duel: duel,
        round: round,
        onProgress: onProgress,
        onFinished: onFinished,
        onExit: onExit,
      );
    }
    return ProviderScope(
      key: ValueKey('${duel.id}-$round'),
      overrides: [
        minigameRandomProvider.overrideWithValue(
          SeededRandom(duel.seedFor(round)),
        ),
        crosswordFixedLevelProvider.overrideWithValue(
          _crosswordLevel(Localizations.localeOf(context).languageCode),
        ),
        // Scoped here so they read the overrides above.
        digitsControllerProvider.overrideWith(DigitsController.new),
        wordsControllerProvider.overrideWith2(WordsController.new),
        crosswordControllerProvider.overrideWith2(CrosswordController.new),
      ],
      child: _MinigameRound(
        game: duel.game,
        onProgress: onProgress,
        onFinished: onFinished,
      ),
    );
  }
}

class _BoardRound extends ConsumerWidget {
  const _BoardRound({
    required this.duel,
    required this.round,
    required this.onProgress,
    required this.onFinished,
    required this.onExit,
  });

  final Duel duel;
  final int round;
  final ValueChanged<DuelProgress> onProgress;
  final ValueChanged<DuelScore> onFinished;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = sharedBoardControllerProvider((
      board: duel.boardFor(round),
      languageCode: duel.languageCode,
    ));
    ref.listen(provider, (previous, next) {
      final progress = DuelRoundHost.boardProgress(previous, next);
      if (progress.event != DuelEvent.none || next.score != previous?.score) {
        onProgress(progress);
      }
      if (next.isCompleted && previous?.isCompleted != true) {
        onFinished(
          DuelScore(
            score: next.score,
            seconds: next.elapsedSeconds,
            moves: next.moves,
          ),
        );
      }
    });

    final board = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    return BoardScreen(
      state: board,
      onCardTap: controller.flipCard,
      onTogglePause: controller.togglePause,
      onHint: controller.useHint,
      // Unreachable: the duel takes over as soon as the round is complete.
      onRestart: () {},
      onExit: onExit,
      lives: 0,
      isLivesUnlimited: true,
      completionOverlay: const SizedBox.shrink(),
    );
  }
}

/// Digits, Words or Crossword, started without their intro and watched
/// until the round ends.
class _MinigameRound extends ConsumerStatefulWidget {
  const _MinigameRound({
    required this.game,
    required this.onProgress,
    required this.onFinished,
  });

  final DuelGame game;
  final ValueChanged<DuelProgress> onProgress;
  final ValueChanged<DuelScore> onFinished;

  @override
  ConsumerState<_MinigameRound> createState() => _MinigameRoundState();
}

class _MinigameRoundState extends ConsumerState<_MinigameRound> {
  final _clock = Stopwatch()..start();
  var _done = false;

  String get _language => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.game) {
        case DuelGame.digits:
          ref.read(digitsControllerProvider.notifier).start(DigitsMode.forward);
        case DuelGame.words:
          ref.read(wordsControllerProvider(_language).notifier).start();
        case DuelGame.crossword || DuelGame.memory:
          break;
      }
    });
  }

  void _report({
    required int score,
    required int solved,
    required int total,
    DuelEvent event = DuelEvent.none,
  }) {
    widget.onProgress(
      DuelProgress(
        round: 0,
        score: score,
        solved: solved,
        total: total,
        event: event,
      ),
    );
  }

  void _finish(int score, int moves) {
    if (_done) return;
    _done = true;
    _clock.stop();
    widget.onFinished(
      DuelScore(score: score, seconds: _clock.elapsed.inSeconds, moves: moves),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.game) {
      case DuelGame.digits:
        ref.listen(digitsControllerProvider, (previous, next) {
          if (previous != null && next.trials > previous.trials) {
            _report(
              score: next.score,
              // Numbers to recall on the way to the target length.
              solved: next.correct,
              total: next.mode.targetSpan - next.mode.startSpan + 1,
              event: next.lastCorrect ? DuelEvent.hit : DuelEvent.miss,
            );
          }
          if (next.phase == DigitsPhase.finished) {
            _finish(next.score, next.trials);
          }
        });
        return const DigitsScreen();
      case DuelGame.words:
        ref.listen(wordsControllerProvider(_language), (previous, next) {
          if (previous != null && next.answered > previous.answered) {
            _report(
              score: next.score,
              solved: next.answered,
              total: next.probes.length,
              event: next.lastAnswerCorrect ? DuelEvent.hit : DuelEvent.miss,
            );
          }
          if (next.phase == WordsPhase.finished) {
            _finish(next.score, next.answered);
          }
        });
        return const WordsScreen();
      case DuelGame.crossword:
        ref.listen(crosswordControllerProvider(_language), (previous, next) {
          final state = next.value;
          if (state == null) return;
          final before = previous?.value;
          if (before != null &&
              (state.attempts != before.attempts ||
                  state.found.length != before.found.length)) {
            _report(
              score: state.score,
              solved: state.found.length,
              total: state.layout.words.length,
              event: state.found.length > before.found.length
                  ? DuelEvent.hit
                  : (state.errors > before.errors
                        ? DuelEvent.miss
                        : DuelEvent.none),
            );
          }
          if (state.solved) _finish(state.score, state.attempts);
        });
        return const CrosswordScreen();
      case DuelGame.memory:
        // Played by _BoardRound.
        return const SizedBox.shrink();
    }
  }
}
