import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/game/board/board_screen.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/lives/controller/lives_controller.dart';
import 'package:memory_companion/features/shop/controller/shop_controller.dart';
import 'package:memory_companion/features/shop/model/plan.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

const _victoryCoinsReward = 50;

/// Connects [BoardController] to [BoardScreen]. Kept separate so
/// [BoardScreen] stays a plain, stateless UI widget.
///
/// Also owns the lives gate: entering the board — and retrying a match —
/// spends one life via [LivesController]; running out shows a native
/// modal nudging the player toward the Shop/Pro plan instead of the game.
///
/// The game mode comes from the route: push [RoutePaths.boardSolo] with a
/// `GameCategory.id` as `arguments` (e.g. `GameCategories.numeric.id`).
/// No argument, or an unknown id, plays the classic game.
class BoardPage extends ConsumerStatefulWidget {
  const BoardPage({super.key});

  @override
  ConsumerState<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends ConsumerState<BoardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _enterMatch());
  }

  BoardSetup get _setup {
    final argument = ModalRoute.of(context)?.settings.arguments;
    return (
      category: GameCategories.byId(argument is String ? argument : null),
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  void _enterMatch() {
    final hasLife = ref.read(livesControllerProvider.notifier).consumeLife();
    if (!hasLife) _showNoLivesDialog(canStayOnBoard: false);
  }

  /// Starts another round — a retry or the next level — if a life is left.
  Future<void> _attemptNewRound(void Function(BoardController) start) async {
    final hasLife = ref.read(livesControllerProvider.notifier).consumeLife();
    if (hasLife) {
      start(ref.read(boardControllerProvider(_setup).notifier));
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
    final provider = boardControllerProvider(_setup);
    ref.listen(provider, (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        ref.read(walletControllerProvider.notifier).add(_victoryCoinsReward);
      }
    });

    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final lives = ref.watch(livesControllerProvider);
    final isLivesUnlimited =
        ref.watch(shopControllerProvider).value?.currentPlanId == PlanId.pro;

    return BoardScreen(
      state: state,
      onCardTap: controller.flipCard,
      onTogglePause: controller.togglePause,
      onHint: controller.useHint,
      onRestart: () => _attemptNewRound((c) => c.restart()),
      onNextLevel: () => _attemptNewRound((c) => c.nextLevel()),
      onExit: () => Navigator.of(context).pop(),
      lives: lives.current,
      isLivesUnlimited: isLivesUnlimited,
    );
  }
}
