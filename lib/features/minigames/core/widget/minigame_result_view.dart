import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/app_card.dart';

/// End-of-round summary shared by the mini-game modules: one headline
/// figure, what it means, a sentence of feedback and the next actions.
///
/// "Back" is always offered last, so every module ends the same way.
class MinigameResultView extends StatelessWidget {
  const MinigameResultView({
    super.key,
    required this.won,
    required this.headline,
    required this.caption,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
  });

  final bool won;

  /// The figure the round is summed up by ("7", "10 of 12 right").
  final String headline;

  /// What [headline] measures.
  final String caption;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = won
        ? (Icons.emoji_events_rounded, AppColors.sunStrong)
        : (Icons.psychology_rounded, AppColors.skyStrong);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, color: color, size: 72),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppLocale.minigameResultTitle.getString(context),
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            children: [
              Text(
                headline,
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(color: color),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                caption,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxl),
        AdaptiveButton(
          label: primaryLabel,
          icon: Icons.play_arrow_rounded,
          onPressed: onPrimary,
        ),
        const SizedBox(height: AppSpacing.md),
        AdaptiveButton(
          label: AppLocale.backToHome.getString(context),
          icon: Icons.arrow_back_rounded,
          variant: AdaptiveButtonVariant.neutral,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}
