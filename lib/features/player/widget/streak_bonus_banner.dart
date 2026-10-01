import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/player/model/player_streak.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// Shown after the first round of the day: the streak just grew and paid.
class StreakBonusBanner extends StatelessWidget {
  const StreakBonusBanner({super.key, required this.streak});

  final StreakUpdate streak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final milestone = isStreakMilestone(streak.currentStreak);
    return AppCard(
      color: AppColors.streakSoft,
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.streakStrong,
            size: AppSize.iconLg,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fill(
                    (milestone
                            ? AppLocale.streakMilestoneTitle
                            : AppLocale.streakDayTitle)
                        .getString(context),
                    streak.currentStreak,
                  ),
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.streakStrong,
                  ),
                ),
                Text(
                  fill(
                    AppLocale.minigameCoinsEarnedLabel.getString(context),
                    streak.bonusCoins,
                  ),
                  style: textTheme.bodyMedium,
                ),
                if (streak.freezesUsed > 0)
                  Text(
                    AppLocale.streakFreezeUsedLabel.getString(context),
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
