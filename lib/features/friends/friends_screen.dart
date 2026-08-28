import 'package:flutter/material.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/widget/invite_friends_card.dart';
import 'package:memory_companion/features/friends/widget/lobby_banner.dart';
import 'package:memory_companion/features/friends/widget/social_network_card.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  static const _friends = [
    Friend(
      initials: 'P1',
      name: 'PlayerOne',
      status: FriendStatus.online,
      avatarColor: AppColors.secondaryContainer,
      onAvatarColor: AppColors.onSecondaryContainer,
    ),
    Friend(
      initials: 'MM',
      name: 'MemoryMaster',
      status: FriendStatus.inGame,
      avatarColor: AppColors.tertiaryFixed,
      onAvatarColor: AppColors.onTertiaryFixedVariant,
    ),
    Friend(
      initials: 'BM',
      name: 'BrightMind',
      status: FriendStatus.offline,
      avatarColor: AppColors.surfaceContainerHigh,
      onAvatarColor: AppColors.onSurfaceVariant,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        activeIndex: 2,
        onTap: (index) => RoutePaths.navigateToTab(context, index),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            HomeTopBar(
              coins: 1250,
              onAvatarTap: () =>
                  Navigator.of(context).pushNamed(RoutePaths.profile),
            ),
            const SizedBox(height: 24),
            InviteFriendsCard(onShare: () {}, onCopyCode: () {}, onInvite: () {}),
            const SizedBox(height: 20),
            const SocialNetworkCard(friends: _friends),
            const SizedBox(height: 20),
            const LobbyBanner(),
          ],
        ),
      ),
    );
  }
}
