import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/model/friend.dart';

/// Loads the player's friend list for the Friends screen.
class FriendsController extends AsyncNotifier<List<Friend>> {
  @override
  Future<List<Friend>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
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
  }
}

final friendsControllerProvider =
    AsyncNotifierProvider<FriendsController, List<Friend>>(
      FriendsController.new,
    );
