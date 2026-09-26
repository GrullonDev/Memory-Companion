import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/pinned_footer_layout.dart';
import 'package:memory_companion/core/widgets/success_pulse.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/digits/controller/digits_controller.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_game_module.dart';
import 'package:memory_companion/features/minigames/modules/digits/model/digits_state.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// The digit-span game. Stateless: everything comes from
/// [digitsControllerProvider].
class DigitsScreen extends ConsumerWidget {
  const DigitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(digitsControllerProvider);
    final controller = ref.read(digitsControllerProvider.notifier);

    final body = switch (state.phase) {
      DigitsPhase.intro => _Intro(onStart: controller.start),
      DigitsPhase.showing => _Showing(state: state),
      DigitsPhase.input => _Input(state: state, controller: controller),
      DigitsPhase.feedback => _Feedback(state: state),
      DigitsPhase.finished => PinnedFooterLayout(
        children: [
          MinigameResultView(
            game: const DigitsGameModule(),
            won: state.won,
            headline: '${state.bestSpan}',
            caption: AppLocale.digitsBestSpanLabel.getString(context),
            message: fill(
              (state.won
                      ? AppLocale.digitsResultWon
                      : AppLocale.digitsResultLost)
                  .getString(context),
              state.mode.targetSpan,
            ),
            primaryLabel: AppLocale.playAgain.getString(context),
            onPrimary: () => controller.start(state.mode),
          ),
        ],
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameDigitsTitle.getString(context)),
      ),
      // Each phase lays itself out: content scrolls, controls stay pinned.
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onStart});

  final void Function(DigitsMode) onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PinnedFooterLayout(
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveButton(
            label: AppLocale.digitsModeForward.getString(context),
            icon: Icons.arrow_forward_rounded,
            onPressed: () => onStart(DigitsMode.forward),
          ),
          const SizedBox(height: AppSpacing.md),
          AdaptiveButton(
            label: AppLocale.digitsModeReverse.getString(context),
            icon: Icons.arrow_back_rounded,
            variant: AdaptiveButtonVariant.secondary,
            onPressed: () => onStart(DigitsMode.reverse),
          ),
        ],
      ),
      children: [
        const Icon(Icons.pin_rounded, color: AppColors.skyStrong, size: 72),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppLocale.digitsIntro.getString(context),
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocale.digitsModeReverseHint.getString(context),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Caption above the number: what to do and how long the number is.
class _Header extends StatelessWidget {
  const _Header({required this.label, required this.span});

  final String label;
  final int span;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          fill(AppLocale.digitsSpanLabel.getString(context), span),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// The number, big and spaced so each digit reads on its own.
class _NumberCard extends StatelessWidget {
  const _NumberCard({required this.text, this.color = AppColors.onSurface});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: color,
            letterSpacing: 6,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

class _Showing extends StatelessWidget {
  const _Showing({required this.state});

  final DigitsState state;

  @override
  Widget build(BuildContext context) {
    return PinnedFooterLayout(
      children: [
        _Header(
          label: AppLocale.digitsMemorizeLabel.getString(context),
          span: state.span,
        ),
        _NumberCard(text: state.sequence),
      ],
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.state, required this.controller});

  final DigitsState state;
  final DigitsController controller;

  @override
  Widget build(BuildContext context) {
    final prompt = state.mode == DigitsMode.reverse
        ? AppLocale.digitsTypeReverse
        : AppLocale.digitsTypeForward;
    // Typed digits, then a dot per digit still missing.
    final slots = state.input.padRight(state.span, '·');

    return PinnedFooterLayout(
      // The keypad never scrolls away from under the thumb.
      footer: _Keypad(
        onDigit: controller.typeDigit,
        onDelete: controller.deleteDigit,
        onSubmit: state.canSubmit ? controller.submit : null,
      ),
      children: [
        _Header(label: prompt.getString(context), span: state.span),
        _NumberCard(text: slots),
      ],
    );
  }
}

/// Phone-style keypad, pinned to the bottom of the screen. Check sits in the
/// bottom row, beside 0, where the thumb already is.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onDelete;

  /// Null until the number is complete.
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Digit keys are labelled by their own text; only the icon key needs one.
    Widget key({
      required Widget child,
      required VoidCallback? onTap,
      String? label,
      Color color = AppColors.surfaceContainerLowest,
    }) {
      return AppCard(
        onTap: onTap,
        color: color,
        padding: EdgeInsets.zero,
        radius: AppRadius.lg,
        semanticLabel: label,
        child: Center(child: child),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.8,
      children: [
        for (final digit in [1, 2, 3, 4, 5, 6, 7, 8, 9])
          key(
            onTap: () => onDigit(digit),
            child: Text('$digit', style: textTheme.headlineSmall),
          ),
        key(
          label: AppLocale.digitsDeleteLabel.getString(context),
          onTap: onDelete,
          child: const Icon(Icons.backspace_outlined, size: AppSize.iconMd),
        ),
        key(
          onTap: () => onDigit(0),
          child: Text('0', style: textTheme.headlineSmall),
        ),
        key(
          label: AppLocale.digitsCheckLabel.getString(context),
          onTap: onSubmit,
          color: onSubmit == null ? AppColors.disabled : AppColors.sun,
          child: Icon(
            Icons.check_rounded,
            size: AppSize.iconLg,
            color: onSubmit == null ? AppColors.onDisabled : AppColors.onSun,
          ),
        ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.state});

  final DigitsState state;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final correct = state.lastCorrect;
    final color = correct ? AppColors.mintStrong : AppColors.error;

    return PinnedFooterLayout(
      children: [
        // A right answer pops; a wrong one just shows what it should have
        // been.
        Center(
          child: SuccessPulse(
            trigger: correct ? state.trials : null,
            playOnMount: true,
            shape: BoxShape.circle,
            haptic: true,
            child: Icon(
              correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: color,
              size: 72,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          correct
              ? AppLocale.minigameCorrectLabel.getString(context)
              : fill(
                  AppLocale.digitsAnswerWas.getString(context),
                  state.expectedAnswer,
                ),
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xl),
        _NumberCard(text: state.input, color: color),
      ],
    );
  }
}
