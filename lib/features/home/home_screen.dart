import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/home/widget/featured_banner.dart';
import 'package:memory_companion/features/home/widget/game_mode_grid.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/home/widget/recent_match_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        onTap: (index) => RoutePaths.navigateToTab(context, index),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const HomeTopBar(coins: 1250),
            const SizedBox(height: 24),
            const FeaturedBanner(),
            const SizedBox(height: 24),
            Text(
              AppLocale.chooseMode.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const GameModeGrid(),
            const SizedBox(height: 24),
            Text(
              AppLocale.recentMatches.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            RecentMatchCard(
              title: AppLocale.sampleMatchTitle.getString(context),
              score: '14,200',
              timeAgo: AppLocale.sampleMatchTimeAgo.getString(context),
            ),
          ],
        ),
      ),
    );
  }
}
