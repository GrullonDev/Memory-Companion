import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/app_typography.dart';
import 'package:memory_companion/core/widgets/app_badge.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/app_progress_bar.dart';
import 'package:memory_companion/features/home/model/home_summary.dart';

/// Level, XP and streak in one strip.
///
/// All three numbers used to live only on the Profile, two taps away, even
/// though the app already stored them — so the Home showed a player no
/// evidence that yesterday counted. Surfacing them here is the cheapest
/// retention change available: the bar is visibly short of full, and the
/// exact XP gap is stated in words.
///
/// The streak badge is an invitation when the streak is zero and a thing
/// worth protecting once it isn't. It never scolds.
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({super.key, required this.summary, this.onTap});

  final HomeSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final numberFormat = NumberFormat.decimalPattern();
    final levelLabel = AppLocale.levelLabel.getString(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      semanticLabel:
          '$levelLabel ${summary.level}. '
          '${AppLocale.levelProgressSemantic.getString(context)}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Level medallion. Deliberately the only circular element in the
          // column, so it reads as a rank rather than as another button.
          Container(
            width: AppSize.wellMd,
            height: AppSize.wellMd,
            decoration: const BoxDecoration(
              color: AppColors.sun,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${summary.level}',
              maxLines: 1,
              style: AppTypography.score(
                context,
                size: 22,
                color: AppColors.onSun,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$levelLabel ${summary.level}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Flexible so a long streak value or a 135% text scale
                    // shrinks the badge instead of overflowing the row.
                    Flexible(
                      child: summary.hasStreak
                          ? AppBadge(
                              icon: Icons.local_fire_department_rounded,
                              label: '${summary.streakDays}',
                              background: AppColors.streakSoft,
                              foreground: AppColors.streakStrong,
                              compact: true,
                            )
                          : const AppBadge.neutral(
                              icon: Icons.local_fire_department_rounded,
                              label: '0',
                              compact: true,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppProgressBar(
                  value: summary.xpProgress,
                  semanticLabel:
                      AppLocale.levelProgressSemantic.getString(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${numberFormat.format(summary.xpRemaining)} '
                  '${AppLocale.xpToNextLabel.getString(context)} '
                  '${summary.nextLevel}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
