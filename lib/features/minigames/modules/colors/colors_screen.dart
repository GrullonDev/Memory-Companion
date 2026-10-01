import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/pinned_footer_layout.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_intro.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/colors/colors_game_module.dart';
import 'package:memory_companion/features/minigames/modules/colors/controller/colors_controller.dart';
import 'package:memory_companion/features/minigames/modules/colors/model/colors_state.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

class ColorsScreen extends ConsumerWidget {
  const ColorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(colorsControllerProvider);
    final controller = ref.read(colorsControllerProvider.notifier);

    final body = switch (state.phase) {
      ColorsPhase.intro => MinigameIntro(
        icon: Icons.palette_rounded,
        color: AppColors.streakStrong,
        level: state.level,
        text: AppLocale.colorsIntro.getString(context),
        onStart: controller.start,
      ),
      ColorsPhase.finished => PinnedFooterLayout(
        children: [
          MinigameResultView(
            game: const ColorsGameModule(),
            won: state.won,
            headline: '${state.correct}/${state.items.length}',
            caption: AppLocale.mathCorrectLabel.getString(context),
            message: fill(
              (state.won
                      ? AppLocale.colorsResultWon
                      : AppLocale.colorsResultLost)
                  .getString(context),
              colorsPassCount,
            ),
            primaryLabel:
                (state.won ? AppLocale.nextLevelLabel : AppLocale.playAgain)
                    .getString(context),
            onPrimary: state.won ? controller.nextLevel : controller.retry,
          ),
        ],
      ),
      _ => _Item(state: state, onPick: controller.pick),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameColorsTitle.getString(context)),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.state, required this.onPick});

  final ColorsState state;
  final ValueChanged<InkColor> onPick;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final item = state.current!;
    final feedback = state.phase == ColorsPhase.feedback;

    return PinnedFooterLayout(
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final color in state.difficulty.colors)
            Semantics(
              button: true,
              label: color.nameKey.getString(context),
              child: GestureDetector(
                onTap: feedback ? null : () => onPick(color),
                child: Container(
                  width: AppSize.touchComfortable + AppSpacing.md,
                  height: AppSize.touchComfortable + AppSpacing.md,
                  decoration: BoxDecoration(
                    color: color.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.onSurface, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
      children: [
        Text(
          '${fill(AppLocale.minigameLevelLabel.getString(context), state.level)}'
          ' · ${state.index + 1}/${state.items.length}',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        TweenAnimationBuilder<double>(
          key: ValueKey('${state.index}-${state.phase}'),
          tween: Tween(begin: 1, end: feedback ? 1 : 0),
          duration: feedback ? Duration.zero : state.difficulty.timeLimit,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: AppSize.progressBarHeight,
              color: value < 0.25 ? AppColors.error : AppColors.streakStrong,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppLocale.colorsQuestion.getString(context),
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.huge,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.word.nameKey.getString(context).toUpperCase(),
              style: textTheme.displayMedium?.copyWith(
                color: item.ink.color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSize.iconLg,
          child: feedback
              ? Icon(
                  state.lastCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: state.lastCorrect
                      ? AppColors.mintStrong
                      : AppColors.error,
                  size: AppSize.iconLg,
                )
              : null,
        ),
      ],
    );
  }
}
