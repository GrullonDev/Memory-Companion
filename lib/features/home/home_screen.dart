import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/core/widgets/section_header.dart';
import 'package:memory_companion/features/home/controller/home_controller.dart';
import 'package:memory_companion/features/home/widget/daily_challenge_card.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/home/widget/level_progress_card.dart';
import 'package:memory_companion/features/home/widget/primary_play_card.dart';
import 'package:memory_companion/features/home/widget/recent_match_card.dart';
import 'package:memory_companion/features/home/widget/secondary_mode_row.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// Coins awarded for clearing the daily challenge.
///
/// Design placeholder: the daily challenge is not implemented yet, so this
/// is the figure the card advertises. Move it to the challenge's own
/// controller once that feature lands.
const int _dailyChallengeReward = 50;

/// The Home, rebuilt around a single clear hierarchy.
///
/// Reading down the screen: who you are and what you own → how far along you
/// are → the one thing to do now → the one thing that brings you back
/// tomorrow → everything else → how you did last time. The previous version
/// gave four modes identical weight in a 2x2 grid while a banner above them
/// offered a fifth, competing call to action pointing at the same route as
/// one of the tiles.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);
    final summary = ref.watch(homeSummaryProvider);
    final recentMatch = ref.watch(homeControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        onTap: (index) => RoutePaths.navigateToTab(context, index),
      ),
      body: SafeArea(
        // The bottom navigation bar already sits inside the bottom inset;
        // padding here as well would double it.
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            // Keeps the column readable on tablets and unfolded devices
            // instead of stretching cards to the full width.
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.lg,
                AppSpacing.screenMargin,
                AppSpacing.xxl,
              ),
              children: [
                HomeTopBar(
                  playerName: summary.playerName,
                  coins: wallet.value ?? 0,
                  onAvatarTap: () =>
                      Navigator.of(context).pushNamed(RoutePaths.profile),
                  onCoinsTap: () =>
                      Navigator.of(context).pushNamed(RoutePaths.shop),
                ),
                const SizedBox(height: AppSpacing.xl),

                LevelProgressCard(
                  summary: summary,
                  onTap: () =>
                      Navigator.of(context).pushNamed(RoutePaths.profile),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // The single primary action.
                PrimaryPlayCard(
                  onTap: () =>
                      Navigator.of(context).pushNamed(RoutePaths.levelMap),
                ),
                const SizedBox(height: AppSpacing.gutter),

                DailyChallengeCard(
                  rewardCoins: _dailyChallengeReward,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocale.comingSoon.getString(context)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                SectionHeader(
                  title: AppLocale.moreModesLabel.getString(context),
                ),
                const SecondaryModeRow(),
                const SizedBox(height: AppSpacing.sectionGap),

                SectionHeader(
                  title: AppLocale.lastMatchLabel.getString(context),
                ),
                AsyncValueView(
                  value: recentMatch,
                  minHeight: 96,
                  onRetry: () => ref.invalidate(homeControllerProvider),
                  data: (context, match) => match.isPlaceholder
                      ? const RecentMatchCard.empty()
                      : RecentMatchCard(
                          title: match.titleKey.getString(context),
                          score: match.score,
                          timeAgo: match.timeAgoKey.getString(context),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
