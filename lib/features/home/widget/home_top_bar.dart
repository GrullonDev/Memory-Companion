import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_stat_chip.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// Identity row: who is playing, and what they own.
///
/// The old top bar centred the app's own name — information the player
/// already has, taking the most valuable strip of the screen. This one leads
/// with the player instead, which is what makes the app feel like *theirs*
/// rather than like a product page.
///
/// Progress (level, XP, streak) deliberately lives one row below, in
/// [LevelProgressCard], so this row stays scannable at a glance.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.playerName,
    required this.coins,
    this.onAvatarTap,
    this.onCoinsTap,
  });

  /// Empty while the profile loads — the fallback keeps the layout stable
  /// instead of collapsing and reflowing when the name arrives.
  final String playerName;
  final int coins;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCoinsTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = playerName.trim().isEmpty
        ? AppLocale.homeGreetingPlayer.getString(context)
        : playerName.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Pressable.small(
          onTap: onAvatarTap,
          semanticLabel: AppLocale.viewProfileLabel.getString(context),
          child: Container(
            width: AppSize.avatarMd,
            height: AppSize.avatarMd,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.sun,
            ),
            child: ClipOval(
              child: Container(
                color: AppColors.surfaceContainerLowest,
                child: Image.asset(
                  'assets/logo_mascota.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                AppLocale.homeReadyPrompt.getString(context),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppStatChip.coins(
          value: NumberFormat.decimalPattern().format(coins),
          onTap: onCoinsTap,
          semanticLabel:
              '${AppLocale.coinsSemanticLabel.getString(context)}: $coins',
        ),
      ],
    );
  }
}
