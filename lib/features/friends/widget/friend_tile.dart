import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/pressable.dart';
import 'package:memory_companion/features/friends/model/friend.dart';

/// One person in the Friends list: avatar with a presence dot, name, a
/// status line, and whatever [actions] fit their relation to the player.
class FriendTile extends StatelessWidget {
  const FriendTile({super.key, required this.friend, this.actions = const []});

  final Friend friend;
  final List<Widget> actions;

  static const _statusColors = {
    FriendStatus.online: AppColors.mintGreen,
    FriendStatus.inGame: AppColors.tertiary,
    FriendStatus.offline: AppColors.outline,
  };

  static const _avatarColors = [
    (AppColors.secondaryContainer, AppColors.onSecondaryContainer),
    (AppColors.tertiaryFixed, AppColors.onTertiaryFixedVariant),
    (AppColors.primaryFixed, AppColors.onPrimaryFixed),
    (AppColors.surfaceContainerHigh, AppColors.onSurfaceVariant),
  ];

  String _subtitle(BuildContext context) {
    final level = '${AppLocale.levelLabel.getString(context)} ${friend.level}';
    return switch (friend.relation) {
      FriendRelation.outgoing => AppLocale.pendingLabel.getString(context),
      FriendRelation.incoming => level,
      FriendRelation.friend =>
        '${switch (friend.status) {
          FriendStatus.online => AppLocale.statusOnline.getString(context),
          FriendStatus.inGame => AppLocale.statusInGame.getString(context),
          FriendStatus.offline => AppLocale.statusOffline.getString(context),
        }} · $level',
    };
  }

  @override
  Widget build(BuildContext context) {
    final (avatarColor, onAvatarColor) =
        _avatarColors[friend.avatarSeed % _avatarColors.length];
    final showPresence = friend.relation == FriendRelation.friend;
    final name = displayNameOr(context, friend.name);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor,
                child: Text(
                  friend.initials,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: onAvatarColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showPresence)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _statusColors[friend.status],
                      border: Border.all(
                        color: AppColors.surfaceContainerLow,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _subtitle(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final action in actions) ...[const SizedBox(width: 6), action],
        ],
      ),
    );
  }
}

/// A round icon action for a [FriendTile].
class FriendTileAction extends StatelessWidget {
  const FriendTileAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.background = AppColors.surfaceContainerHigh,
    this.foreground = AppColors.onSurfaceVariant,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable.small(
        onTap: onTap,
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: foreground),
          ),
        ),
      ),
    );
  }
}

/// [name], or a generic "Player" for someone who never set one.
String displayNameOr(BuildContext context, String name) => name.trim().isEmpty
    ? AppLocale.unknownPlayerName.getString(context)
    : name.trim();

/// "Remove {name}?" before a friendship is ended for good.
Future<bool> confirmRemoveFriend(BuildContext context, Friend friend) async {
  final name = displayNameOr(context, friend.name);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      content: Text(
        AppLocale.removeFriendConfirm
            .getString(dialogContext)
            .replaceAll('{name}', name),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(AppLocale.notNowLabel.getString(dialogContext)),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(AppLocale.removeFriendLabel.getString(dialogContext)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
