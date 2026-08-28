import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/game/board/board_screen.dart';
import 'package:memory_companion/features/game/board/controller/board_controller.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

const _victoryCoinsReward = 50;

/// Connects [BoardController] to [BoardScreen]. Kept separate so
/// [BoardScreen] stays a plain, stateless UI widget.
class BoardPage extends ConsumerWidget {
  const BoardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(boardControllerProvider, (previous, next) {
      if (next.isCompleted && previous?.isCompleted != true) {
        ref.read(walletControllerProvider.notifier).add(_victoryCoinsReward);
      }
    });

    final state = ref.watch(boardControllerProvider);
    final controller = ref.read(boardControllerProvider.notifier);

    return BoardScreen(
      state: state,
      onCardTap: controller.flipCard,
      onTogglePause: controller.togglePause,
      onHint: controller.useHint,
      onRestart: controller.restart,
      onExit: () => Navigator.of(context).pop(),
    );
  }
}
