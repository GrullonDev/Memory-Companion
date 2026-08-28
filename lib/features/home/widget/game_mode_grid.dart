import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/home/widget/game_mode_card.dart';

class GameModeGrid extends StatelessWidget {
  const GameModeGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        GameModeCard(
          icon: Icons.person,
          label: AppLocale.modePlaySolo.getString(context),
          background: AppColors.primaryFixed,
          foreground: AppColors.onPrimaryFixed,
          onTap: () => Navigator.of(context).pushNamed(RoutePaths.levelMap),
        ),
        GameModeCard(
          icon: Icons.groups,
          label: AppLocale.modeMultiplayer.getString(context),
          background: AppColors.secondaryContainer,
          foreground: AppColors.onSecondaryContainer,
          onTap: () {},
        ),
        GameModeCard(
          icon: Icons.calendar_month,
          label: AppLocale.modeDailyChallenge.getString(context),
          background: AppColors.mintGreen,
          foreground: AppColors.onMintGreen,
          onTap: () {},
        ),
        GameModeCard(
          icon: Icons.shopping_bag,
          label: AppLocale.modeShop.getString(context),
          background: AppColors.pastelPurple,
          foreground: AppColors.onPastelPurple,
          badge: AppLocale.badgePro.getString(context),
          onTap: () {},
        ),
      ],
    );
  }
}
