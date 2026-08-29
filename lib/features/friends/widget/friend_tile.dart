import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/model/friend.dart';

class FriendTile extends StatelessWidget {
  const FriendTile({super.key, required this.friend, this.onTrailingTap});

  final Friend friend;
  final VoidCallback? onTrailingTap;

  static const _statusColors = {
    FriendStatus.online: AppColors.mintGreen,
    FriendStatus.inGame: AppColors.tertiary,
    FriendStatus.offline: AppColors.outline,
  };

  String _statusLabel(BuildContext context) {
    return switch (friend.status) {
      FriendStatus.online => AppLocale.statusOnline.getString(context),
      FriendStatus.inGame => AppLocale.statusInGame.getString(context),
      FriendStatus.offline => AppLocale.statusOffline.getString(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _statusColors[friend.status]!;
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
                backgroundColor: friend.avatarColor,
                child: Text(
                  friend.initials,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: friend.onAvatarColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
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
                  friend.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _statusLabel(context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (friend.status == FriendStatus.online)
            _TrailingButton(
              icon: Icons.add_rounded,
              background: AppColors.primaryFixed,
              foreground: AppColors.onPrimaryFixed,
              onTap: onTrailingTap,
            )
          else if (friend.status == FriendStatus.inGame)
            _TrailingButton(
              icon: Icons.sports_esports_rounded,
              background: AppColors.surfaceContainerHigh,
              foreground: AppColors.onSurfaceVariant,
              onTap: onTrailingTap,
            ),
        ],
      ),
    );
  }
}

class _TrailingButton extends StatelessWidget {
  const _TrailingButton({
    required this.icon,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: foreground),
        ),
      ),
    );
  }
}
