import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/app_progress_bar.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/words/controller/words_controller.dart';
import 'package:memory_companion/features/minigames/modules/words/model/words_state.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// The word-recognition game, dealt in the app's current language.
/// Stateless: everything comes from [wordsControllerProvider].
class WordsScreen extends ConsumerWidget {
  const WordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = wordsControllerProvider(
      Localizations.localeOf(context).languageCode,
    );
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    final body = switch (state.phase) {
      WordsPhase.intro => _Intro(onStart: controller.start),
      WordsPhase.study => _Study(state: state, onReady: controller.finishStudy),
      WordsPhase.test => _Test(state: state, controller: controller),
      WordsPhase.finished => MinigameResultView(
        won: state.won,
        headline: _ofTotal(
          AppLocale.wordsScoreLabel.getString(context),
          state.correct,
          state.probes.length,
        ),
        caption: fill(
          AppLocale.wordsLevelLabel.getString(context),
          state.listSize,
        ),
        message: state.won
            ? fill(
                AppLocale.wordsResultWon.getString(context),
                state.nextListSize,
              )
            : AppLocale.wordsResultLost.getString(context),
        primaryLabel:
            (state.won ? AppLocale.nextLevelLabel : AppLocale.playAgain)
                .getString(context),
        onPrimary: state.won ? controller.nextLevel : controller.start,
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameWordsTitle.getString(context)),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [body],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fills a template with a `{n}` count out of a `{total}`.
String _ofTotal(String template, int n, int total) =>
    fill(template, n).replaceAll('{total}', '$total');

class _Intro extends StatelessWidget {
  const _Intro({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.menu_book_rounded,
          color: AppColors.violetStrong,
          size: 72,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppLocale.wordsIntro.getString(context),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AdaptiveButton(
          label: AppLocale.minigameStartLabel.getString(context),
          icon: Icons.play_arrow_rounded,
          onPressed: onStart,
        ),
      ],
    );
  }
}

class _Study extends StatelessWidget {
  const _Study({required this.state, required this.onReady});

  final WordsState state;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocale.wordsStudyTitle.getString(context),
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          fill(AppLocale.wordsLevelLabel.getString(context), state.listSize),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final word in state.studied)
              AppCard(
                color: AppColors.violetSoft,
                radius: AppRadius.lg,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Text(
                  word,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.violetStrong,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AdaptiveButton(
          label: AppLocale.wordsReadyLabel.getString(context),
          icon: Icons.check_rounded,
          onPressed: onReady,
        ),
      ],
    );
  }
}

class _Test extends StatelessWidget {
  const _Test({required this.state, required this.controller});

  final WordsState state;
  final WordsController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = state.probes.length;
    final showLast = state.answered > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _ofTotal(
            AppLocale.wordsProgressLabel.getString(context),
            state.answered + 1,
            total,
          ),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(value: state.answered / total),
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppLocale.wordsQuestion.getString(context),
          textAlign: TextAlign.center,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.huge,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              state.currentProbe ?? '',
              style: textTheme.displaySmall,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // How the previous answer went: quick feedback without a pause.
        SizedBox(
          height: AppSize.iconLg,
          child: showLast
              ? Icon(
                  state.lastAnswerCorrect
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: state.lastAnswerCorrect
                      ? AppColors.mintStrong
                      : AppColors.error,
                  size: AppSize.iconLg,
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AdaptiveButton(
          label: AppLocale.wordsYesLabel.getString(context),
          icon: Icons.visibility_rounded,
          variant: AdaptiveButtonVariant.secondary,
          onPressed: () => controller.answer(wasOnList: true),
        ),
        const SizedBox(height: AppSpacing.md),
        AdaptiveButton(
          label: AppLocale.wordsNoLabel.getString(context),
          icon: Icons.visibility_off_rounded,
          variant: AdaptiveButtonVariant.neutral,
          onPressed: () => controller.answer(wasOnList: false),
        ),
      ],
    );
  }
}
