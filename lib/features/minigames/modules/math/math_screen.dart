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
import 'package:memory_companion/features/minigames/modules/math/controller/math_controller.dart';
import 'package:memory_companion/features/minigames/modules/math/math_game_module.dart';
import 'package:memory_companion/features/minigames/modules/math/model/math_state.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

class MathScreen extends ConsumerWidget {
  const MathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mathControllerProvider);
    final controller = ref.read(mathControllerProvider.notifier);

    final body = switch (state.phase) {
      MathPhase.intro => MinigameIntro(
        icon: Icons.calculate_rounded,
        color: AppColors.sunStrong,
        level: state.level,
        text: fill(
          AppLocale.mathIntro.getString(context),
          mathPassCount,
        ).replaceAll('{total}', '$mathProblemsPerRound'),
        onStart: controller.start,
      ),
      MathPhase.finished => PinnedFooterLayout(
        children: [
          MinigameResultView(
            game: const MathGameModule(),
            won: state.won,
            headline: '${state.correct}/${state.problems.length}',
            caption: AppLocale.mathCorrectLabel.getString(context),
            message: fill(
              (state.won ? AppLocale.mathResultWon : AppLocale.mathResultLost)
                  .getString(context),
              mathPassCount,
            ),
            primaryLabel:
                (state.won ? AppLocale.nextLevelLabel : AppLocale.playAgain)
                    .getString(context),
            onPrimary: state.won ? controller.nextLevel : controller.retry,
          ),
        ],
      ),
      _ => _Problem(state: state, onPick: controller.pick),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameMathTitle.getString(context)),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.state, required this.onPick});

  final MathState state;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final problem = state.current!;
    final feedback = state.phase == MathPhase.feedback;

    return PinnedFooterLayout(
      footer: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.2,
        children: [
          for (final choice in problem.choices)
            AppCard(
              onTap: feedback ? null : () => onPick(choice),
              color: !feedback
                  ? AppColors.sunSoft
                  : choice == problem.answer
                  ? AppColors.mintSoft
                  : choice == state.picked
                  ? AppColors.errorContainer
                  : AppColors.surfaceContainerLow,
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Center(
                child: FittedBox(
                  child: Text('$choice', style: textTheme.headlineMedium),
                ),
              ),
            ),
        ],
      ),
      children: [
        Text(
          '${fill(AppLocale.minigameLevelLabel.getString(context), state.level)}'
          ' · ${state.index + 1}/${state.problems.length}',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        // Restarts with every problem; frozen while the feedback shows.
        TweenAnimationBuilder<double>(
          key: ValueKey('${state.index}-${state.phase}'),
          tween: Tween(begin: 1, end: feedback ? 1 : 0),
          duration: feedback ? Duration.zero : state.difficulty.timeLimit,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: value,
              minHeight: AppSize.progressBarHeight,
              color: value < 0.25 ? AppColors.error : AppColors.sunStrong,
              backgroundColor: AppColors.surfaceContainerHigh,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.huge,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${problem.text} = ?', style: textTheme.displaySmall),
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
