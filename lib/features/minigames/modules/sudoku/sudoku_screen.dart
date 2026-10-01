import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/pinned_footer_layout.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_intro.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/controller/sudoku_controller.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/model/sudoku_state.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/sudoku_game_module.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/widget/sudoku_grid.dart';
import 'package:memory_companion/features/shop/controller/store_controller.dart';
import 'package:memory_companion/features/shop/model/store_item.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

class SudokuScreen extends ConsumerWidget {
  const SudokuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sudokuControllerProvider);
    final controller = ref.read(sudokuControllerProvider.notifier);

    final body = switch (state.phase) {
      SudokuPhase.intro => MinigameIntro(
        icon: Icons.grid_3x3_rounded,
        color: AppColors.skyStrong,
        level: state.level,
        text: AppLocale.sudokuIntro.getString(context),
        onStart: controller.start,
      ),
      SudokuPhase.playing => _Playing(state: state, controller: controller),
      SudokuPhase.finished => PinnedFooterLayout(
        children: [
          MinigameResultView(
            game: const SudokuGameModule(),
            won: state.won,
            headline: '${state.filled}/${state.holes}',
            caption: AppLocale.sudokuCellsLabel.getString(context),
            message:
                (state.won
                        ? AppLocale.sudokuResultWon
                        : AppLocale.sudokuResultLost)
                    .getString(context),
            primaryLabel:
                (state.won ? AppLocale.nextLevelLabel : AppLocale.playAgain)
                    .getString(context),
            onPrimary: state.won ? controller.nextLevel : controller.retry,
          ),
        ],
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameSudokuTitle.getString(context)),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Playing extends ConsumerWidget {
  const _Playing({required this.state, required this.controller});

  final SudokuState state;
  final SudokuController controller;

  Future<void> _hint(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final noHints = AppLocale.sudokuNoHints.getString(context);
    if (!await controller.hint()) {
      messenger.showSnackBar(SnackBar(content: Text(noHints)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final size = state.difficulty.shape.size;
    final owned = ref.watch(inventoryProvider).value?[InventoryKind.hint] ?? 0;
    final hintsLeft = state.freeHintsLeft + owned;

    return PinnedFooterLayout(
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (var v = 1; v <= size; v++)
            _NumberKey(
              value: v,
              // A number already on the grid [size] times has no place left.
              onTap: state.countOf(v) >= size
                  ? null
                  : () => controller.enter(v),
            ),
        ],
      ),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fill(
                  AppLocale.minigameLevelLabel.getString(context),
                  state.level,
                ),
                style: textTheme.titleMedium,
              ),
            ),
            Text(
              fill(
                AppLocale.sudokuMistakesLabel.getString(context),
                state.mistakes,
              ).replaceAll('{total}', '${state.difficulty.maxMistakes}'),
              style: textTheme.bodyMedium?.copyWith(
                color: state.mistakes > 0
                    ? AppColors.error
                    : AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Badge.count(
              count: hintsLeft,
              isLabelVisible: hintsLeft > 0,
              child: IconButton.filledTonal(
                onPressed: () => _hint(context),
                tooltip: AppLocale.sudokuHintLabel.getString(context),
                icon: const Icon(Icons.lightbulb_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SudokuGrid(state: state, onSelect: controller.select),
      ],
    );
  }
}

class _NumberKey extends StatelessWidget {
  const _NumberKey({required this.value, required this.onTap});

  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSize.touchComfortable,
      height: AppSize.touchComfortable,
      child: AdaptiveButton(
        label: '$value',
        variant: AdaptiveButtonVariant.secondary,
        onPressed: onTap,
      ),
    );
  }
}
