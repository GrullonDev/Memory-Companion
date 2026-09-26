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
import 'package:memory_companion/features/friends/controller/nearby_search_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';
import 'package:memory_companion/features/friends/widget/invite_friends_card.dart';
import 'package:memory_companion/features/friends/widget/lobby_banner.dart';
import 'package:memory_companion/features/friends/widget/nearby_players_card.dart';
import 'package:memory_companion/features/friends/widget/play_room_card.dart';
import 'package:memory_companion/features/friends/widget/social_network_card.dart';
import 'package:memory_companion/features/friends/widget/social_sign_in_card.dart';
import 'package:memory_companion/features/home/controller/home_controller.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/versus/widget/duel_game_picker.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
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

  void _playRoom(BuildContext context, Duel room) {
    Navigator.of(context).pushNamed(RoutePaths.duel, arguments: room);
  }

  Future<void> _createRoom(BuildContext context, WidgetRef ref) async {
    final game = await showDuelGamePicker(
      context,
      initial: ref.read(selectedDuelGameProvider),
    );
    if (game == null || !context.mounted) return;
    ref.read(selectedDuelGameProvider.notifier).select(game);
    final room = await ref
        .read(versusControllerProvider.notifier)
        .createRoom(
          languageCode: Localizations.localeOf(context).languageCode,
          game: game,
        );
    if (!context.mounted) return;
    final code = room?.roomCode;
    if (room == null || code == null) {
      _notify(context, AppLocale.duelCreateFailed);
      return;
    }
    final play = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _RoomCreatedDialog(
        code: code,
        onCopy: () => _copyCode(dialogContext, code),
        onShare: () => SharePlus.instance.share(
          ShareParams(
            text: AppLocale.roomInviteShareText
                .getString(dialogContext)
                .replaceAll('{code}', code),
          ),
        ),
      ),
    );
    if (play == true && context.mounted) _playRoom(context, room);
  }

  Future<bool> _joinRoom(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final result = await ref
        .read(versusControllerProvider.notifier)
        .joinRoom(code);
    if (!context.mounted) return false;
    final room = result.duel;
    if (result.status == JoinRoomStatus.joined && room != null) {
      _playRoom(context, room);
      return true;
    }
    _notify(context, switch (result.status) {
      JoinRoomStatus.invalidCode => AppLocale.friendCodeInvalid,
      JoinRoomStatus.notFound => AppLocale.roomNotFound,
      JoinRoomStatus.joined ||
      JoinRoomStatus.signedOut ||
      JoinRoomStatus.failed => AppLocale.socialActionFailed,
    });
    return false;
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
                    PlayRoomCard(
                      onCreate: () => _createRoom(context, ref),
                      onJoin: (code) => _joinRoom(context, ref, code),
                    ),
                    const SizedBox(height: 20),
                    NearbyPlayersCard(
                      state: ref.watch(nearbySearchControllerProvider),
                      onSearch: () => ref
                          .read(nearbySearchControllerProvider.notifier)
                          .search(),
                      onAdd: (code) => _add(context, ref, code),
                      onChallenge: (friend) => _challenge(context, ref, friend),
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

/// The code of a room just opened, with ways to send it and to start
/// playing. Pops `true` when the host chooses to play now.
class _RoomCreatedDialog extends StatelessWidget {
  const _RoomCreatedDialog({
    required this.code,
    required this.onCopy,
    required this.onShare,
  });

  final String code;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      title: Text(AppLocale.roomCreatedTitle.getString(context)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocale.roomCreatedMessage.getString(context),
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            code,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: AppLocale.copyCodeLabel.getString(context),
                icon: const Icon(Icons.copy_rounded),
                onPressed: onCopy,
              ),
              IconButton(
                tooltip: AppLocale.inviteLinkLabel.getString(context),
                icon: const Icon(Icons.share_rounded),
                onPressed: onShare,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocale.notNowLabel.getString(context)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(AppLocale.playLabel.getString(context)),
        ),
      ],
    );
  }
}
