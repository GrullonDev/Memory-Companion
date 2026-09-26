import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';

/// A ladder reward, announced as its own moment on a result screen: a gift every
/// [LevelRewards.every] levels, a chest every [LevelRewards.chestEvery].
class LevelRewardCard extends StatelessWidget {
  const LevelRewardCard({super.key, required this.reward});

  final LevelReward reward;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title =
        (reward.isChest
                ? AppLocale.levelRewardChestTitle
                : AppLocale.levelRewardGiftTitle)
            .getString(context);
    final coins = AppLocale.levelRewardCoins
        .getString(context)
        .replaceAll('{coins}', '${reward.coins}');

    return Semantics(
      liveRegion: true,
      label: '$title $coins',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: reward.isChest ? AppColors.violetSoft : AppColors.sunSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Icon(
              reward.isChest
                  ? Icons.inventory_2_rounded
                  : Icons.card_giftcard_rounded,
              size: AppSize.iconXl,
              color: reward.isChest
                  ? AppColors.violetStrong
                  : AppColors.sunStrong,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: reward.isChest
                          ? AppColors.onViolet
                          : AppColors.onSun,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    coins,
                    style: textTheme.bodyLarge?.copyWith(
                      color: reward.isChest
                          ? AppColors.onViolet
                          : AppColors.onSun,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
