import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_badge.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/game_icon.dart';

/// The daily challenge, promoted to its own full-width card.
///
/// This is the only element on the Home whose job is tomorrow rather than
/// today, so it gets a weight of its own — second only to the primary play
/// card — instead of sharing a 2x2 grid with the shop. It states the reward
/// up front, because "come back tomorrow" is a much weaker ask than "come
/// back tomorrow for 50 coins".
///
/// Status is carried by an icon and a word as well as by colour, so it reads
/// correctly for a colour-blind player.
class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({
    super.key,
    required this.rewardCoins,
    this.completed = false,
    this.onTap,
  });

  /// Coins granted for clearing today's challenge.
  final int rewardCoins;

  /// Whether today's challenge is already done.
  final bool completed;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = AppLocale.modeDailyChallenge.getString(context);
    final statusLabel = completed
        ? AppLocale.dailyChallengeDoneLabel.getString(context)
        : AppLocale.dailyChallengeAvailableLabel.getString(context);

    return AppCard(
      onTap: onTap,
      color: AppColors.mint,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadow: AppShadows.tinted(AppColors.mintDeep),
      pressedShadow: AppShadows.tinted(AppColors.mintDeep, pressed: true),
      semanticLabel: '$title. $statusLabel',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GameIcon(
            icon: completed
                ? Icons.check_circle_rounded
                : Icons.event_available_rounded,
            color: AppColors.onMint,
            background: Colors.white.withValues(alpha: 0.38),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.onMint,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  AppLocale.dailyChallengeSubtitle.getString(context),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onMint.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Wrap, not Row: on a small screen or at 135% text scale the
                // two badges stack instead of overflowing.
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppBadge(
                      icon: Icons.monetization_on_rounded,
                      label: '+$rewardCoins',
                      background: Colors.white.withValues(alpha: 0.92),
                      foreground: AppColors.sunStrong,
                    ),
                    AppBadge(
                      icon: completed
                          ? Icons.check_rounded
                          : Icons.schedule_rounded,
                      label: statusLabel,
                      background: AppColors.onMint.withValues(alpha: 0.16),
                      foreground: AppColors.onMint,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.onMint,
              size: AppSize.iconMd,
            ),
          ),
        ],
      ),
    );
  }
}
