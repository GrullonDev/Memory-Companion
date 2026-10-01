import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/app_progress_bar.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/model/player_streak.dart';
import 'package:memory_companion/features/shop/controller/store_controller.dart';
import 'package:memory_companion/features/shop/model/store_item.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// The play streak at a glance: days in a row, whether today already
/// counts, what tomorrow pays, how far the next milestone is and the
/// freezes held.
///
/// Any finished round of any game keeps the streak going.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(localPlayerProvider).value;
    if (player == null) return const SizedBox.shrink();
    final freezes =
        ref.watch(inventoryProvider).value?[InventoryKind.streakFreeze] ?? 0;
    final textTheme = Theme.of(context).textTheme;

    final (:status, :days) = streakStatusAt(
      lastPlayedDate: player.lastPlayedDate,
      currentStreak: player.currentStreak,
      now: DateTime.now(),
      availableFreezes: freezes,
    );
    final next = nextStreakMilestone(days);
    final previous = [0, ...streakMilestones].lastWhere((m) => m <= days);
    final (message, payDay) = switch (status) {
      // Already played: what tomorrow's first round will pay.
      StreakStatus.safe => (AppLocale.streakSafeLabel, days + 1),
      StreakStatus.atRisk => (AppLocale.streakAtRiskLabel, days + 1),
      StreakStatus.none => (AppLocale.streakStartBonusLabel, 1),
    };

    return AppCard(
      color: AppColors.streakSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: status == StreakStatus.none
                    ? AppColors.onSurfaceVariant
                    : AppColors.streakStrong,
                size: AppSize.iconXl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fill(AppLocale.streakCountLabel.getString(context), days),
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.streakStrong,
                      ),
                    ),
                    Text(
                      fill(message.getString(context), streakDayCoins(payDay)),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (freezes > 0)
                Tooltip(
                  message: AppLocale.storeStreakFreezeTitle.getString(context),
                  child: Chip(
                    avatar: const Icon(Icons.ac_unit_rounded, size: 18),
                    label: Text('$freezes'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: (days - previous) / (next - previous)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            fill(
              AppLocale.streakNextMilestoneLabel.getString(context),
              next,
            ).replaceAll('{coins}', '${streakDayCoins(next)}'),
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
