import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/widget/board_bottom_bar.dart';
import 'package:memory_companion/features/game/board/widget/board_grid.dart';
import 'package:memory_companion/features/game/board/widget/board_paused_overlay.dart';
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
  });

  final BoardState state;
  final ValueChanged<int> onCardTap;
  final VoidCallback onTogglePause;
  final VoidCallback onHint;
  final VoidCallback onRestart;
  final VoidCallback onExit;

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
                  BoardTopBar(progress: state.progress, moves: state.moves),
                  const SizedBox(height: 32),
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
                onSettings: () {},
                onQuit: onExit,
              ),
            if (state.isCompleted)
              BoardVictoryOverlay(
                score: state.score,
                elapsedSeconds: state.elapsedSeconds,
                coinsEarned: 50,
                onPlayAgain: onRestart,
                onExit: onExit,
              ),
          ],
        ),
      ),
    );
  }
}
