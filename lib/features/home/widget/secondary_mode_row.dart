import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/home/widget/game_mode_card.dart';

/// The two supporting modes, side by side.
///
/// The old 2x2 grid gave Play Solo, Multiplayer, Daily Challenge and Shop
/// exactly equal weight, while two of those four tiles simply duplicated
/// tabs that already exist in the bottom navigation. Solo and the daily
/// challenge are now promoted above; these two stay as tiles, smaller, in
/// their own colours.
///
/// Layout adapts rather than assuming a width: side by side when there is
/// room, stacked when the screen is narrow or the player has enlarged the
/// system font.
class SecondaryModeRow extends StatelessWidget {
  const SecondaryModeRow({super.key});

  /// Narrowest width at which two tiles still read comfortably side by side.
  /// Two 150dp tiles plus the gutter; below it the row becomes a column.
  static const double _minTwoColumnWidth = 300;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = <Widget>[
          GameModeCard(
            icon: Icons.groups_rounded,
            label: AppLocale.modeMultiplayer.getString(context),
            description: AppLocale.multiplayerSubtitle.getString(context),
            background: AppColors.sky,
            foreground: AppColors.onSky,
            shadowColor: AppColors.skyDeep,
            onTap: () => Navigator.of(context).pushNamed(RoutePaths.versus),
          ),
          GameModeCard(
            icon: Icons.storefront_rounded,
            label: AppLocale.modeShop.getString(context),
            description: AppLocale.shopSubtitle.getString(context),
            background: AppColors.violet,
            foreground: AppColors.onViolet,
            shadowColor: AppColors.violetDeep,
            badge: AppLocale.badgePro.getString(context),
            onTap: () => Navigator.of(context).pushNamed(RoutePaths.shop),
          ),
        ];

        // Below this width, or once text is meaningfully enlarged, two
        // columns stop being readable — a stacked list is better than a
        // squeezed row.
        final stack =
            constraints.maxWidth < _minTwoColumnWidth || textScale > 1.2;

        if (stack) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.gutter),
                SizedBox(width: double.infinity, child: cards[i]),
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.gutter),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      },
    );
  }
}
