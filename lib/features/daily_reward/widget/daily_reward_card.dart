import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_badge.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/floating_bob.dart';
import 'package:memory_companion/features/daily_reward/model/daily_reward.dart';

/// The daily chest on the Home.
///
/// Loud while there is something to claim — warm colour, a bobbing chest,
/// the multiplier up front — and quiet once claimed, when it only says what
/// tomorrow holds. Like the daily challenge card, the status reads from an
/// icon and a word as well as from colour.
class DailyRewardCard extends StatelessWidget {
  const DailyRewardCard({super.key, required this.status, this.onTap});

  final DailyRewardStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final available = status.available;
    final background = available ? AppColors.streak : AppColors.streakSoft;
    final foreground = available ? Colors.white : AppColors.onStreak;
    final title = AppLocale.dailyRewardTitle.getString(context);
    final subtitle = available
        ? AppLocale.dailyRewardReady
              .getString(context)
              .replaceAll('{day}', '${status.streak}')
        : AppLocale.dailyRewardClaimedToday.getString(context);

    final chest = Icon(
      status.reward.isChestDay
          ? Icons.inventory_2_rounded
          : Icons.card_giftcard_rounded,
      color: available ? Colors.white : AppColors.streakStrong,
      size: AppSize.iconXl,
    );

    return AppCard(
      onTap: onTap,
      color: background,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      shadow: AppShadows.tinted(AppColors.streakDeep),
      pressedShadow: AppShadows.tinted(AppColors.streakDeep, pressed: true),
      semanticLabel: '$title. $subtitle',
      child: Row(
        children: [
          Container(
            width: AppSize.wellLg,
            height: AppSize.wellLg,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: available ? 0.24 : 0.7),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.center,
            child: available ? FloatingBob(child: chest) : chest,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(color: foreground),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: '${status.streak}',
                      background: Colors.white.withValues(alpha: 0.92),
                      foreground: AppColors.streakStrong,
                    ),
                    AppBadge(
                      icon: Icons.bolt_rounded,
                      label: multiplierLabel(status.reward.multiplier),
                      background: Colors.white.withValues(alpha: 0.92),
                      foreground: AppColors.sunStrong,
                    ),
                    AppBadge(
                      icon: available
                          ? Icons.redeem_rounded
                          : Icons.schedule_rounded,
                      label: available
                          ? AppLocale.dailyRewardClaim.getString(context)
                          : AppLocale.dailyRewardTomorrow.getString(context),
                      background: foreground.withValues(alpha: 0.16),
                      foreground: foreground,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: foreground,
            size: AppSize.iconMd,
          ),
        ],
      ),
    );
  }
}

/// `x1.25`, `x2`: no trailing zeros.
String multiplierLabel(double multiplier) {
  final text = multiplier.toStringAsFixed(2);
  final trimmed = text.replaceFirst(RegExp(r'\.?0+$'), '');
  return 'x$trimmed';
}
