import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/widget/invite_friends_card.dart';
import 'package:memory_companion/features/friends/widget/lobby_banner.dart';
import 'package:memory_companion/features/friends/widget/social_network_card.dart';
import 'package:memory_companion/features/home/controller/home_controller.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  static const _inviteCode = 'XJ4Q9';
  static const _inviteLink = 'https://memoryarcade.app/invite/$_inviteCode';

  Future<void> _copyAndNotify(
    BuildContext context,
    String text,
    String messageKey,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(messageKey.getString(context))));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);
    final summary = ref.watch(homeSummaryProvider);
    final friends = ref.watch(friendsControllerProvider);

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
              playerName: summary.playerName,
              coins: wallet.value ?? 0,
              onAvatarTap: () =>
                  Navigator.of(context).pushNamed(RoutePaths.profile),
            ),
            const SizedBox(height: 24),
            InviteFriendsCard(
              onShare: () => _copyAndNotify(
                context,
                _inviteLink,
                AppLocale.linkCopiedMessage,
              ),
              onCopyCode: () => _copyAndNotify(
                context,
                _inviteCode,
                AppLocale.codeCopiedMessage,
              ),
              onInvite: () => _copyAndNotify(
                context,
                _inviteLink,
                AppLocale.inviteSentMessage,
              ),
            ),
            const SizedBox(height: 20),
            AsyncValueView(
              value: friends,
              onRetry: () => ref.invalidate(friendsControllerProvider),
              data: (context, friends) => SocialNetworkCard(friends: friends),
            ),
            const SizedBox(height: 20),
            const LobbyBanner(),
          ],
        ),
      ),
    );
  }
}
