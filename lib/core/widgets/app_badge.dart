import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';

/// A small pill that qualifies the thing it sits on: "Pro", "Nuevo",
/// "Completado", a count.
///
/// Badges always pair an icon (or a shape) with text. Colour alone never
/// carries the meaning, so the badge still works for a colour-blind player
/// and in a screenshot printed in greyscale.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.streak,
    this.foreground = AppColors.onStreak,
    this.compact = false,
  });

  /// Muted variant for neutral metadata that should not compete with the
  /// card's own colour.
  const AppBadge.neutral({
    super.key,
    required this.label,
    this.icon,
    this.compact = false,
  })  : background = AppColors.surfaceContainerHigh,
        foreground = AppColors.onSurfaceVariant;

  /// Confirmation variant — a finished daily challenge, an unlocked item.
  const AppBadge.success({
    super.key,
    required this.label,
    this.icon = Icons.check_rounded,
    this.compact = false,
  })  : background = AppColors.mintSoft,
        foreground = AppColors.mintStrong;

  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;

  /// Drops the horizontal padding for use inside a dense row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSize.iconXs, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
