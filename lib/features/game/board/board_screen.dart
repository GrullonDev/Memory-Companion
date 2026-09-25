import 'package:flutter/material.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/widget/board_bottom_bar.dart';
import 'package:memory_companion/features/game/board/widget/board_grid.dart';
import 'package:memory_companion/features/game/board/widget/board_paused_overlay.dart';
import 'package:memory_companion/features/game/board/widget/board_preview_banner.dart';
import 'package:memory_companion/features/game/board/widget/board_top_bar.dart';
import 'package:memory_companion/features/game/board/widget/board_victory_overlay.dart';

/// Pure UI for the solo memory board. All game logic lives in
/// [BoardController]; this widget only renders [state] and forwards taps.
class BoardScreen extends StatelessWidget {
  const BoardScreen({
    super.key,
    required this.state,
    required this.onCardTap,
    required this.onTogglePause,
    required this.onHint,
    required this.onRestart,
    required this.onExit,
    required this.lives,
    required this.isLivesUnlimited,
    this.onNextLevel,
    this.completionOverlay,
  });

  final BoardState state;
  final ValueChanged<int> onCardTap;
  final VoidCallback onTogglePause;
  final VoidCallback onHint;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final int lives;
  final bool isLivesUnlimited;

  /// The result screen's primary action after a win. Falls back to
  /// [onRestart] — the next round is dealt with the adjusted difficulty
  /// either way.
  final VoidCallback? onNextLevel;

  /// Replaces the standard victory overlay when the board is completed.
  /// The daily challenge uses it for its share screen.
  final Widget? completionOverlay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                children: [
                  BoardTopBar(
                    progress: state.progress,
                    moves: state.moves,
                    isTimed: state.isTimed,
                    lives: lives,
                    isLivesUnlimited: isLivesUnlimited,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: state.isPreviewing
                        ? BoardPreviewBanner(
                            secondsRemaining: state.previewSecondsRemaining,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Center(
                      child: BoardGrid(
                        cards: state.cards,
                        onCardTap: onCardTap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BoardBottomBar(
                    isPaused: state.isPaused,
                    onTogglePause: onTogglePause,
                    onHint: onHint,
                  ),
                ],
              ),
            ),
            if (state.isPaused && !state.isCompleted)
              BoardPausedOverlay(
                onResume: onTogglePause,
                // The match stays paused underneath; changes apply from the
                // next round.
                onSettings: () =>
                    Navigator.of(context).pushNamed(RoutePaths.settings),
                onQuit: onExit,
              ),
            if (state.isCompleted && completionOverlay != null)
              completionOverlay!
            else if (state.isCompleted)
              BoardVictoryOverlay(
                won: state.won,
                stars: state.stars,
                score: state.score,
                moves: state.moves,
                elapsedSeconds: state.elapsedSeconds,
                coinsEarned: state.coinsEarned,
                xpEarned: state.xpEarned,
                completedLevel: state.won ? state.level : null,
                levelReward: state.levelReward,
                onNextLevel: onNextLevel ?? onRestart,
                onPlayAgain: onRestart,
                onViewStats: () =>
                    Navigator.of(context).pushNamed(RoutePaths.statistics),
                onExit: onExit,
              ),
          ],
        ),
      ),
    );
  }
}
