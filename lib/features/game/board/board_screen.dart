import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/widget/board_bottom_bar.dart';
import 'package:memory_companion/features/game/board/widget/board_grid.dart';
import 'package:memory_companion/features/game/board/widget/board_top_bar.dart';

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
              _BoardOverlay(
                title: AppLocale.pausedTitle.getString(context),
                subtitle: AppLocale.pausedSubtitle.getString(context),
                actionLabel: AppLocale.resumeGame.getString(context),
                onAction: onTogglePause,
                onExit: onExit,
              ),
            if (state.isCompleted)
              _BoardOverlay(
                title: AppLocale.completedTitle.getString(context),
                subtitle: AppLocale.completedSubtitle.getString(context),
                actionLabel: AppLocale.playAgain.getString(context),
                onAction: onRestart,
                onExit: onExit,
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardOverlay extends StatelessWidget {
  const _BoardOverlay({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.onExit,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x99000000),
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryFixed,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onPrimaryFixed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onExit,
              child: Text(
                AppLocale.backToHome.getString(context),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: AppColors.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
