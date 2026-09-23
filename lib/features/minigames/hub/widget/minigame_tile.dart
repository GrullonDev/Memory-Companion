import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/game_icon.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';

/// One mini-game in the hub: a big icon, its name and one line saying what
/// it trains.
///
/// Same anatomy as the Home's `GameModeCard`, for the same reasons: height
/// follows the content (no fixed aspect ratio, so large text never clips),
/// and the whole tile is a single, generous tap target.
class MinigameTile extends StatelessWidget {
  const MinigameTile({super.key, required this.game, required this.onTap});

  final BaseMinigame game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = game.palette;
    final title = game.titleKey.getString(context);
    final description = game.descriptionKey.getString(context);
    final wellColor = Colors.white.withValues(alpha: 0.38);
    final asset = game.iconAsset;

    return AppCard(
      onTap: onTap,
      color: palette.background,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      constraints: const BoxConstraints(
        minHeight: AppSize.secondaryCardMinHeight,
      ),
      shadow: AppShadows.tinted(palette.shadow),
      pressedShadow: AppShadows.tinted(palette.shadow, pressed: true),
      semanticLabel: '$title. $description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset == null)
            GameIcon.large(
              icon: game.icon,
              color: palette.foreground,
              background: wellColor,
            )
          else
            Container(
              width: AppSize.wellLg,
              height: AppSize.wellLg,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: wellColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    Icon(game.icon, color: palette.foreground),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(color: palette.foreground),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: palette.foreground.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
