import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/game/board/board_screen.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/lives/controller/lives_controller.dart';
import 'package:memory_companion/features/shop/controller/shop_controller.dart';
import 'package:memory_companion/features/shop/model/plan.dart';

/// Connects [BoardController] to [BoardScreen]. Kept separate so
/// [BoardScreen] stays a plain, stateless UI widget.
///
/// Also owns the lives gate: entering the board — and retrying a match —
/// spends one life via [LivesController]; running out shows a native
/// modal nudging the player toward the Shop/Pro plan instead of the game.
class BoardPage extends ConsumerStatefulWidget {
  const BoardPage({super.key});

  @override
  ConsumerState<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends ConsumerState<BoardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_enterMatch()));
  }

  Future<void> _enterMatch() async {
    final hasLife =
        await ref.read(livesControllerProvider.notifier).consumeLife();
    if (!hasLife && mounted) _showNoLivesDialog(canStayOnBoard: false);
  }

  Future<void> _attemptRestart() async {
    final hasLife =
        await ref.read(livesControllerProvider.notifier).consumeLife();
    if (!mounted) return;
    if (hasLife) {
      ref.read(boardControllerProvider.notifier).restart();
    } else {
      await _showNoLivesDialog(canStayOnBoard: true);
    }
  }

  Future<void> _showNoLivesDialog({required bool canStayOnBoard}) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        icon: const Icon(
          Icons.favorite_border_rounded,
          color: AppColors.error,
          size: 32,
        ),
        title: Text(
          AppLocale.noLivesTitle.getString(dialogContext),
          textAlign: TextAlign.center,
        ),
        content: Text(
          AppLocale.noLivesMessage.getString(dialogContext),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!canStayOnBoard) Navigator.of(context).pop();
            },
            child: Text(AppLocale.notNowLabel.getString(dialogContext)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (!canStayOnBoard) Navigator.of(context).pop();
              Navigator.of(context).pushNamed(RoutePaths.shop);
            },
            child: Text(AppLocale.goToShopLabel.getString(dialogContext)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(boardControllerProvider);
    final controller = ref.read(boardControllerProvider.notifier);
    // Las vidas se cargan de la base local, así que llegan como AsyncValue.
    // Mientras resuelven se muestra el máximo: es un instante y no bloquea el
    // tablero, que ya está jugable.
    final lives = ref.watch(livesControllerProvider).value;
    final isLivesUnlimited =
        ref.watch(shopControllerProvider).value?.currentPlanId ==
        PlanId.pro;

    return BoardScreen(
      state: state,
      onCardTap: controller.flipCard,
      onTogglePause: controller.togglePause,
      onHint: controller.useHint,
      onRestart: _attemptRestart,
      onExit: () => Navigator.of(context).pop(),
      lives: lives?.current ?? LivesController.maxLives,
      isLivesUnlimited: isLivesUnlimited,
    );
  }
}
