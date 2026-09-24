import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';
import 'package:memory_companion/features/friends/widget/invite_friends_card.dart';
import 'package:memory_companion/features/friends/widget/lobby_banner.dart';
import 'package:memory_companion/features/friends/widget/social_network_card.dart';
import 'package:memory_companion/features/friends/widget/social_sign_in_card.dart';
import 'package:memory_companion/features/home/controller/home_controller.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  static const _tabIndex = 2;

  void _notify(BuildContext context, String messageKey) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(messageKey.getString(context))));
  }

  Future<void> _copyCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) _notify(context, AppLocale.codeCopiedMessage);
  }

  Future<void> _shareCode(BuildContext context, String code) {
    return SharePlus.instance.share(
      ShareParams(
        text: AppLocale.friendInviteShareText
            .getString(context)
            .replaceAll('{code}', code),
      ),
    );
  }

  Future<bool> _add(BuildContext context, WidgetRef ref, String code) async {
    final result = await ref
        .read(friendsControllerProvider.notifier)
        .addByCode(code);
    if (!context.mounted) return false;
    _notify(context, switch (result) {
      AddFriendResult.sent => AppLocale.friendRequestSent,
      AddFriendResult.accepted => AppLocale.friendRequestAccepted,
      AddFriendResult.invalidCode => AppLocale.friendCodeInvalid,
      AddFriendResult.notFound => AppLocale.friendNotFound,
      AddFriendResult.self => AppLocale.friendSelfCode,
      AddFriendResult.alreadyFriends => AppLocale.alreadyFriendsMessage,
      AddFriendResult.alreadyPending => AppLocale.alreadyPendingMessage,
      AddFriendResult.signedOut ||
      AddFriendResult.failed => AppLocale.socialActionFailed,
    });
    return result == AddFriendResult.sent || result == AddFriendResult.accepted;
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    Friend friend,
  ) async {
    final ok = await ref
        .read(friendsControllerProvider.notifier)
        .accept(friend);
    if (!context.mounted) return;
    _notify(
      context,
      ok ? AppLocale.friendRequestAccepted : AppLocale.socialActionFailed,
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    Friend friend,
  ) async {
    // Only an accepted friendship asks first: declining or cancelling a
    // request loses nothing that cannot be sent again.
    if (friend.relation == FriendRelation.friend &&
        !await confirmRemoveFriend(context, friend)) {
      return;
    }
    final ok = await ref
        .read(friendsControllerProvider.notifier)
        .remove(friend);
    if (!ok && context.mounted) _notify(context, AppLocale.socialActionFailed);
  }

  void _challenge(BuildContext context, WidgetRef ref, Friend friend) {
    ref.read(selectedRivalProvider.notifier).select(friend.uid);
    Navigator.of(context).pushReplacementNamed(RoutePaths.versus);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Opening Friends marks the player online. Failures only mean they show
    // as offline to others, so the result is not watched for errors.
    ref.watch(socialPresenceProvider);

    final wallet = ref.watch(walletControllerProvider);
    final summary = ref.watch(homeSummaryProvider);
    final friends = ref.watch(friendsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        activeIndex: _tabIndex,
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
            AsyncValueView<FriendsState>(
              value: friends,
              minHeight: 240,
              onRetry: () => ref.invalidate(friendsControllerProvider),
              data: (context, state) {
                final code = state.friendCode;
                if (!state.isSignedIn || code == null) {
                  return const SocialSignInCard();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InviteFriendsCard(
                      friendCode: code,
                      onShare: () => _shareCode(context, code),
                      onCopyCode: () => _copyCode(context, code),
                    ),
                    const SizedBox(height: 20),
                    SocialNetworkCard(
                      state: state,
                      onAdd: (input) => _add(context, ref, input),
                      onAccept: (friend) => _accept(context, ref, friend),
                      onRemove: (friend) => _remove(context, ref, friend),
                      onChallenge: (friend) => _challenge(context, ref, friend),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const LobbyBanner(),
          ],
        ),
      ),
    );
  }
}
