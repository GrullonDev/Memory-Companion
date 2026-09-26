import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/daily_challenge/controller/daily_challenge_controller.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_challenge.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_result.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_streak.dart';
import 'package:memory_companion/features/daily_challenge/widget/daily_result_overlay.dart';
import 'package:memory_companion/features/game/board/board_screen.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/widget/board_grid.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// Plays today's challenge, or shows today's result if it is already done.
///
/// Unlike [BoardPage] it does not spend a life: the daily challenge is the
/// reason to come back tomorrow, and gating it behind lives would undercut
/// that. It also offers no retry, since the board is identical for everyone
/// and a second go would be played from memory.
class DailyChallengePage extends ConsumerStatefulWidget {
  const DailyChallengePage({super.key});

  @override
  ConsumerState<DailyChallengePage> createState() => _DailyChallengePageState();
}

class _DailyChallengePageState extends ConsumerState<DailyChallengePage> {
  /// Fixed when the page opens: playing across midnight finishes the
  /// challenge that was started, not the next day's.
  late final DailyChallenge _challenge = ref.read(todayChallengeProvider);

  /// Set the moment this visit completes the board, so the result shows
  /// immediately instead of waiting for the database round trip.
  DailyResult? _finished;

  DailyBoardSetup get _setup => (
    challenge: _challenge,
    languageCode: Localizations.localeOf(context).languageCode,
  );

  Future<void> _onCompleted(BoardState board) async {
    final result = DailyResult.fromBoard(
      dateKey: _challenge.dateKey,
      number: _challenge.number,
      cards: board.cards,
      columns: BoardGrid.columnsFor(board.cards.length),
      elapsedSeconds: board.elapsedSeconds,
      moves: board.moves,
      hintsUsed: board.hintsUsed,
      score: board.score,
    );
    setState(() => _finished = result);

    final player = await ref.read(localPlayerProvider.future);
    final isFirstCompletion = await ref
        .read(dailyChallengeRepositoryProvider)
        .saveResult(playerId: player.localId, result: result);
    // Only the first completion pays out, however the page was reached.
    if (isFirstCompletion) {
      ref
          .read(walletControllerProvider.notifier)
          .add(DailyChallenge.rewardCoins);
    }
  }

  void _exit() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(dailyStatusProvider(_challenge));
    final streak = status.value?.streak ?? DailyStreak.empty;

    final finished = _finished;
    if (finished == null) {
      // Wait for the status before dealing: a finished challenge must not
      // flash its board, and dealing starts the preview clock.
      if (!status.hasValue && !status.hasError) {
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      final earlier = status.value?.today;
      if (earlier != null) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: DailyResultOverlay(
              result: earlier,
              streak: streak,
              celebrate: false,
              onExit: _exit,
            ),
          ),
        );
      }
    }

    final provider = dailyBoardControllerProvider(_setup);
    ref.listen(provider, (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        _onCompleted(next);
      }
    });

    final board = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return BoardScreen(
      state: board,
      onCardTap: controller.flipCard,
      onTogglePause: controller.togglePause,
      onHint: controller.useHint,
      // Unreachable: the daily result replaces the overlay that offers it.
      onRestart: () {},
      onExit: _exit,
      lives: 0,
      isLivesUnlimited: true,
      completionOverlay: finished == null
          ? null
          : DailyResultOverlay(
              result: finished,
              streak: streak,
              celebrate: true,
              onExit: _exit,
            ),
    );
  }
}
