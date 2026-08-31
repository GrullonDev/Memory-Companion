import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/app_typography.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// A pill showing one live number: coins, a streak, lives, a rank.
///
/// The icon is what a pre-reader recognises; the number is what an adult
/// reads. Both are always present, which is why this is a chip and not a
/// bare figure. Numbers use tabular figures so the pill does not resize
/// every time the value ticks.
class AppStatChip extends StatelessWidget {
  const AppStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.background,
    required this.foreground,
    this.onTap,
    this.semanticLabel,
  });

  /// Coins — the app's yellow currency pill.
  const AppStatChip.coins({
    super.key,
    required this.value,
    this.onTap,
    this.semanticLabel,
  })  : icon = Icons.monetization_on_rounded,
        background = AppColors.sunSoft,
        foreground = AppColors.sunStrong;

  /// Daily streak — orange, because it is the one number with urgency.
  const AppStatChip.streak({
    super.key,
    required this.value,
    this.onTap,
    this.semanticLabel,
  })  : icon = Icons.local_fire_department_rounded,
        background = AppColors.streakSoft,
        foreground = AppColors.streakStrong;

  final IconData icon;
  final String value;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      constraints: const BoxConstraints(minHeight: AppSize.touchMin),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.iconSm, color: foreground),
          const SizedBox(width: AppSpacing.xs + 2),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.score(
                context,
                size: 16,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: semanticLabel, child: chip);
    }

    return Pressable.small(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: chip,
    );
  }
}
