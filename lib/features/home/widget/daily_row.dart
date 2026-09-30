import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/floating_bob.dart';
import 'package:memory_companion/features/daily_reward/model/daily_reward.dart';

/// Today's two reasons to come back — the chest and the challenge — as two
/// compact tiles side by side.
///
/// They used to be two tall full-width cards with three badges each, which
/// pushed the games below the fold. Each tile now says one thing: what it is
/// and whether it's waiting for you. Details live one tap away.
class DailyRow extends StatelessWidget {
  const DailyRow({
    super.key,
    required this.reward,
    required this.challengeCompleted,
    required this.challengeCoins,
    this.onRewardTap,
    this.onChallengeTap,
  });

  /// Null while loading; the challenge tile then fills the row alone.
  final DailyRewardStatus? reward;
  final bool challengeCompleted;
  final int challengeCoins;
  final VoidCallback? onRewardTap;
  final VoidCallback? onChallengeTap;

  @override
  Widget build(BuildContext context) {
    final reward = this.reward;
    final challenge = _DailyTile(
      icon: challengeCompleted
          ? Icons.check_circle_rounded
          : Icons.event_available_rounded,
      title: AppLocale.modeDailyChallenge.getString(context),
      status: challengeCompleted
          ? AppLocale.dailyChallengeDoneLabel.getString(context)
          : '+$challengeCoins',
      active: !challengeCompleted,
      background: AppColors.mint,
      foreground: AppColors.onMint,
      shadow: AppColors.mintDeep,
      onTap: onChallengeTap,
    );

    // Stack when text is enlarged; two squeezed tiles read worse than a list.
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final tiles = [
      if (reward != null)
        _DailyTile(
          icon: reward.reward.isChestDay
              ? Icons.inventory_2_rounded
              : Icons.card_giftcard_rounded,
          title: AppLocale.dailyRewardTitle.getString(context),
          status: reward.available
              ? AppLocale.dailyRewardClaim.getString(context)
              : AppLocale.dailyRewardTomorrow.getString(context),
          active: reward.available,
          background: reward.available
              ? AppColors.streak
              : AppColors.streakSoft,
          foreground: reward.available ? Colors.white : AppColors.onStreak,
          shadow: AppColors.streakDeep,
          onTap: onRewardTap,
        ),
      challenge,
    ];

    if (textScale > 1.2) {
      return Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.gutter),
            SizedBox(width: double.infinity, child: tiles[i]),
          ],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.gutter),
            Expanded(child: tiles[i]),
          ],
        ],
      ),
    );
  }
}

class _DailyTile extends StatelessWidget {
  const _DailyTile({
    required this.icon,
    required this.title,
    required this.status,
    required this.active,
    required this.background,
    required this.foreground,
    required this.shadow,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String status;

  /// Something is waiting to be claimed or played; the icon bobs.
  final bool active;
  final Color background;
  final Color foreground;
  final Color shadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final iconWidget = Icon(icon, color: foreground, size: AppSize.iconLg);

    return AppCard(
      onTap: onTap,
      color: background,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.md),
      shadow: AppShadows.tinted(shadow),
      pressedShadow: AppShadows.tinted(shadow, pressed: true),
      semanticLabel: '$title. $status',
      child: Row(
        children: [
          active ? FloatingBob(child: iconWidget) : iconWidget,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(color: foreground),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: foreground.withValues(alpha: 0.85),
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
