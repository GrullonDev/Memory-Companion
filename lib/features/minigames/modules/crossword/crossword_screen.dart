import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/crossword/controller/crossword_controller.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_state.dart';
import 'package:memory_companion/features/minigames/modules/crossword/widget/crossword_grid.dart';
import 'package:memory_companion/features/minigames/modules/crossword/widget/letter_wheel.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// The word-wheel crossword, in the app's current language. Stateless:
/// everything comes from [crosswordControllerProvider].
class CrosswordScreen extends ConsumerWidget {
  const CrosswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = crosswordControllerProvider(
      Localizations.localeOf(context).languageCode,
    );
    final value = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameCrosswordTitle.getString(context)),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.screenMargin),
              children: [
                AsyncValueView<CrosswordState>(
                  value: value,
                  onRetry: () => ref.invalidate(provider),
                  data: (context, state) => state.solved
                      ? _Solved(state: state, onNext: controller.nextLevel)
                      : _Board(state: state, controller: controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state, required this.controller});

  final CrosswordState state;
  final CrosswordController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final highlight = state.feedback == CrosswordFeedback.found
        ? state.layout.wordOf(state.feedbackWord).cells.toSet()
        : const <(int, int)>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                fill(
                  AppLocale.crosswordLevelLabel.getString(context),
                  state.levelNumber,
                ),
                style: textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                fill(
                  AppLocale.crosswordProgressLabel.getString(context),
                  state.found.length,
                ).replaceAll('{total}', '${state.layout.words.length}'),
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        CrosswordGrid(
          layout: state.layout,
          revealed: state.revealed,
          highlight: highlight,
        ),
        const SizedBox(height: AppSpacing.md),
        _FeedbackLine(state: state),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              onPressed: controller.shuffle,
              tooltip: AppLocale.crosswordShuffleLabel.getString(context),
              icon: const Icon(Icons.shuffle_rounded),
            ),
            IconButton.filledTonal(
              onPressed: controller.hint,
              tooltip: AppLocale.crosswordHintLabel.getString(context),
              icon: const Icon(Icons.lightbulb_outline_rounded),
            ),
          ],
        ),
        LetterWheel(letters: state.wheel, onWord: controller.submit),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppLocale.crosswordInstructions.getString(context),
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// What happened to the last word entered. Announced to screen readers as
/// it changes. Fixed height, so the wheel below never moves.
class _FeedbackLine extends StatelessWidget {
  const _FeedbackLine({required this.state});

  final CrosswordState state;

  @override
  Widget build(BuildContext context) {
    final (key, color) = switch (state.feedback) {
      CrosswordFeedback.found => (
        AppLocale.crosswordFoundFeedback,
        AppColors.mintStrong,
      ),
      CrosswordFeedback.repeated => (
        AppLocale.crosswordRepeatedFeedback,
        AppColors.onSurfaceVariant,
      ),
      CrosswordFeedback.invalid => (
        AppLocale.crosswordInvalidFeedback,
        AppColors.error,
      ),
      null => (null, AppColors.onSurfaceVariant),
    };

    return SizedBox(
      height: 28,
      child: Semantics(
        liveRegion: true,
        child: Text(
          key == null ? '' : fill(key.getString(context), state.feedbackWord),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
          ),
        ),
      ),
    );
  }
}

class _Solved extends StatelessWidget {
  const _Solved({required this.state, required this.onNext});

  final CrosswordState state;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return MinigameResultView(
      won: true,
      headline: fill(
        AppLocale.crosswordLevelLabel.getString(context),
        state.levelNumber,
      ),
      caption: AppLocale.crosswordLevelCleared.getString(context),
      message: state.hintsUsed == 0
          ? AppLocale.crosswordCompleteNoHints.getString(context)
          : fill(
              AppLocale.crosswordCompleteMessage.getString(context),
              state.hintsUsed,
            ),
      primaryLabel: AppLocale.nextLevelLabel.getString(context),
      onPrimary: onNext,
    );
  }
}
