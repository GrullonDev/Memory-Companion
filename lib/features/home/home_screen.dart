import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/notifications/notification_route_handler.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/routes/tab_root_scope.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/section_header.dart';
import 'package:memory_companion/features/account/controller/account_link_controller.dart';
import 'package:memory_companion/features/account/widget/link_conflict_dialog.dart';
import 'package:memory_companion/features/account/widget/save_progress_card.dart';
import 'package:memory_companion/features/daily_challenge/controller/daily_challenge_controller.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_challenge.dart';
import 'package:memory_companion/features/daily_reward/controller/daily_reward_controller.dart';
import 'package:memory_companion/features/daily_reward/widget/daily_reward_dialog.dart';
import 'package:memory_companion/features/home/controller/home_controller.dart';
import 'package:memory_companion/features/home/widget/daily_row.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/home/widget/level_progress_card.dart';
import 'package:memory_companion/features/home/widget/primary_play_card.dart';
import 'package:memory_companion/features/minigames/hub/widget/minigame_carousel.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// The Home, rebuilt around a single clear hierarchy.
///
/// Five blocks, top to bottom: who you are → how far along you are → the one
/// thing to do now → today's rewards → the other games. Versus and Friends
/// live in the bottom nav, so they are not repeated here.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cuando una cuenta trae progreso propio, el jugador decide con cuál se
    // queda. Adivinar por él es como se pierde el progreso de alguien.
    ref.listen(accountLinkControllerProvider, (previous, next) {
      final link = next.value;
      final local = link?.localProfile;
      final cloud = link?.cloudProfile;
      if (link == null || !link.needsChoice || local == null || cloud == null) {
        return;
      }

      showLinkConflictDialog(context, local: local, cloud: cloud).then((
        choice,
      ) {
        final controller = ref.read(accountLinkControllerProvider.notifier);
        switch (choice) {
          case LinkChoice.keepLocal:
            controller.keepLocalProgress();
          case LinkChoice.keepCloud:
            controller.keepCloudProgress();
          case null:
            break;
        }
      });
    });

    final wallet = ref.watch(walletControllerProvider);
    final summary = ref.watch(homeSummaryProvider);
    final dailyStatus = ref.watch(
      dailyStatusProvider(ref.watch(todayChallengeProvider)),
    );
    final minigames = ref.watch(minigamesProvider);
    final dailyReward = ref.watch(dailyRewardControllerProvider).value;

    return TabRootScope(
      isHome: true,
      child: NotificationRouteHandler(
        child: Scaffold(
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
                      // Hidden while the plans shop is in development.
                      // onCoinsTap: () =>
                      //     Navigator.of(context).pushNamed(RoutePaths.shop),
                      onSettingsTap: () =>
                          Navigator.of(context).pushNamed(RoutePaths.settings),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Main ladder only; every game's ladder is on the Profile.
                    LevelProgressCard(
                      summary: summary,
                      showAllLadders: false,
                      onTap: () =>
                          Navigator.of(context).pushNamed(RoutePaths.profile),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // The single primary action.
                    PrimaryPlayCard(
                      onTap: () =>
                          Navigator.of(context).pushNamed(RoutePaths.levelMap),
                    ),
                    const SizedBox(height: AppSpacing.gutter),

                    // Aparece solo cuando el jugador ya tiene algo que perder.
                    const SaveProgressCard(),

                    // Today's reasons to come back, one compact row.
                    DailyRow(
                      reward: dailyReward,
                      challengeCompleted:
                          dailyStatus.value?.completedToday ?? false,
                      challengeCoins: DailyChallenge.rewardCoins,
                      onRewardTap: () => showDailyRewardDialog(context),
                      onChallengeTap: () => Navigator.of(
                        context,
                      ).pushNamed(RoutePaths.dailyChallenge),
                    ),
                    const SizedBox(height: AppSpacing.sectionGap),

                    SectionHeader(
                      title: AppLocale.brainGamesLabel.getString(context),
                      actionLabel: AppLocale.seeAllLabel.getString(context),
                      onAction: () => Navigator.of(
                        context,
                      ).pushNamed(RoutePaths.minigameHub),
                    ),
                    MinigameCarousel(games: minigames),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
