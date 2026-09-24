import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/controller/nearby_search_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';

/// "Near you": finds players around over Bluetooth, to add or challenge
/// them without typing a code.
class NearbyPlayersCard extends StatelessWidget {
  const NearbyPlayersCard({
    super.key,
    required this.state,
    required this.onSearch,
    required this.onAdd,
    required this.onChallenge,
  });

  final NearbySearchState state;
  final VoidCallback onSearch;
  final ValueChanged<String> onAdd;
  final ValueChanged<Friend> onChallenge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final searching = state.status == NearbySearchStatus.searching;
    final supporting = textTheme.bodyMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
    );

    final message = switch (state.status) {
      NearbySearchStatus.permissionDenied => AppLocale.nearbyPermissionDenied,
      NearbySearchStatus.unavailable => AppLocale.nearbyUnavailable,
      NearbySearchStatus.done when state.found.isEmpty =>
        AppLocale.nearbyNoneFound,
      _ => null,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          top: BorderSide(color: AppColors.primaryFixed, width: 4),
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
              const Icon(
                Icons.bluetooth_searching_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocale.nearbyTitle.getString(context),
                  style: textTheme.titleLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(AppLocale.nearbySubtitle.getString(context), style: supporting),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: searching ? null : onSearch,
              style: FilledButton.styleFrom(
                minimumSize: const Size(48, 48),
                backgroundColor: AppColors.primaryFixed,
                foregroundColor: AppColors.onPrimaryFixed,
              ),
              icon: searching
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.radar_rounded),
              label: Text(
                (searching
                        ? AppLocale.nearbySearching
                        : AppLocale.nearbySearchLabel)
                    .getString(context),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message.getString(context), style: supporting),
          ],
          for (final found in state.found) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primaryFixed,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.onPrimaryFixed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    found.name,
                    style: textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _action(context, found),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(BuildContext context, NearbyFound found) {
    final friend = found.friend;
    if (friend == null) {
      return OutlinedButton(
        onPressed: () => onAdd(found.code),
        child: Text(AppLocale.addFriendLabel.getString(context)),
      );
    }
    if (friend.relation == FriendRelation.friend) {
      return FilledButton(
        onPressed: () => onChallenge(friend),
        child: Text(AppLocale.challengeLabel.getString(context)),
      );
    }
    return Text(
      AppLocale.nearbyPendingLabel.getString(context),
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: AppColors.outline),
    );
  }
}
