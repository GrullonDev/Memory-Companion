import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';

class SocialNetworkCard extends StatelessWidget {
  const SocialNetworkCard({super.key, required this.friends});

  final List<Friend> friends;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          top: BorderSide(color: AppColors.tertiaryFixed, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: AppColors.tertiary),
              const SizedBox(width: 8),
              Text(
                AppLocale.socialNetworkTitle.getString(context),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.outline),
                const SizedBox(width: 8),
                Text(
                  AppLocale.findByUsernameHint.getString(context),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final friend in friends) ...[
            FriendTile(friend: friend),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
