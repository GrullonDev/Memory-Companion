import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_badge.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/game_icon.dart';

/// A secondary game-mode tile: multiplayer, shop.
///
/// Two changes from the previous version matter beyond looks:
///
///  * **No fixed aspect ratio.** The old grid forced a 1.2 ratio, which on a
///    360dp-wide phone produced a 126dp-tall cell for ~140dp of content —
///    an overflow on every small screen. Height is now driven by the content
///    with a minimum, so it grows with long labels and large text settings
///    instead of clipping.
///  * **The badge is in the layout, not floating outside it.** The old badge
///    was `Positioned(top: -8)` inside a `GridView`, which clips its
///    children, so it was cut off. It now sits in the column where it can
///    never be trimmed.
///
/// Every tile carries an icon, a name and a one-line description: the icon
/// for players who cannot read yet, the description for adults deciding
/// whether the tap is worth it.
class GameModeCard extends StatelessWidget {
  const GameModeCard({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.background,
    required this.foreground,
    required this.shadowColor,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// One short line saying what the mode is for.
  final String description;

  final Color background;

  /// Text and icon colour. Always a dark tint of [background]'s own hue, so
  /// the pair clears 4.5:1 without introducing white-on-colour text.
  final Color foreground;

  /// Hue used for the tinted drop shadow.
  final Color shadowColor;

  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      color: background,
      radius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.lg),
      constraints: const BoxConstraints(
        minHeight: AppSize.secondaryCardMinHeight,
      ),
      shadow: AppShadows.tinted(shadowColor),
      pressedShadow: AppShadows.tinted(shadowColor, pressed: true),
      semanticLabel: '$label. $description',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(
            icon: icon,
            color: foreground,
            background: Colors.white.withValues(alpha: 0.38),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(color: foreground),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: foreground.withValues(alpha: 0.78),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppBadge(
              icon: Icons.workspace_premium_rounded,
              label: badge!,
              background: Colors.white.withValues(alpha: 0.92),
              foreground: foreground,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }
}
