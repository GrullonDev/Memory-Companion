import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/model/duel.dart';

/// The player's duels: whose turn it is, who they are waiting on, and how
/// the finished ones went.
class DuelListCard extends StatelessWidget {
  const DuelListCard({
    super.key,
    required this.state,
    required this.onPlay,
    required this.onDecline,
  });

  final VersusState state;
  final ValueChanged<Duel> onPlay;
  final ValueChanged<Duel> onDecline;

  @override
  Widget build(BuildContext context) {
    final uid = state.uid;
    if (uid == null ||
        (state.toPlay.isEmpty &&
            state.waiting.isEmpty &&
            state.finished.isEmpty)) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;

    String rivalName(Duel duel) =>
        displayNameOr(context, state.nameOf(duel.rivalOf(uid)));

    Widget section(String titleKey) => Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        titleKey.getString(context),
        style: textTheme.labelLarge?.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.toPlay.isNotEmpty) ...[
            section(AppLocale.duelsToPlayTitle),
            for (final duel in state.toPlay)
              _DuelRow(
                icon: Icons.sports_esports_rounded,
                iconColor: AppColors.skyStrong,
                title:
                    (duel.isInvitationFor(uid)
                            ? AppLocale.duelChallengeFrom
                            : AppLocale.duelOwnChallenge)
                        .getString(context)
                        .replaceAll('{name}', rivalName(duel)),
                actions: [
                  if (duel.isInvitationFor(uid))
                    FriendTileAction(
                      icon: Icons.close_rounded,
                      tooltip: AppLocale.declineLabel.getString(context),
                      onTap: () => onDecline(duel),
                    ),
                  FriendTileAction(
                    icon: Icons.play_arrow_rounded,
                    tooltip: AppLocale.playLabel.getString(context),
                    background: AppColors.primaryFixed,
                    foreground: AppColors.onPrimaryFixed,
                    onTap: () => onPlay(duel),
                  ),
                ],
              ),
          ],
          if (state.waiting.isNotEmpty) ...[
            section(AppLocale.duelsWaitingTitle),
            for (final duel in state.waiting)
              _DuelRow(
                icon: Icons.hourglass_top_rounded,
                iconColor: AppColors.onSurfaceVariant,
                title: AppLocale.duelWaitingFor
                    .getString(context)
                    .replaceAll('{name}', rivalName(duel)),
                subtitle: fill(
                  AppLocale.duelPointsLabel.getString(context),
                  duel.resultOf(uid)?.score ?? 0,
                ),
                onTap: () => onPlay(duel),
              ),
          ],
          if (state.finished.isNotEmpty) ...[
            section(AppLocale.duelsFinishedTitle),
            for (final duel in state.finished)
              _finishedRow(context, duel, uid, rivalName(duel)),
          ],
        ],
      ),
    );
  }

  Widget _finishedRow(
    BuildContext context,
    Duel duel,
    String uid,
    String rivalName,
  ) {
    final vs = AppLocale.duelVsLabel
        .getString(context)
        .replaceAll('{name}', rivalName);
    final points = AppLocale.duelPointsLabel.getString(context);
    final (icon, color, labelKey) = switch (duel.outcomeFor(uid)) {
      DuelOutcome.won => (
        Icons.emoji_events_rounded,
        AppColors.sunStrong,
        AppLocale.duelWonLabel,
      ),
      DuelOutcome.lost => (
        Icons.close_rounded,
        AppColors.error,
        AppLocale.duelLostLabel,
      ),
      DuelOutcome.draw => (
        Icons.handshake_rounded,
        AppColors.skyStrong,
        AppLocale.duelDrawLabel,
      ),
      null => (
        Icons.block_rounded,
        AppColors.outline,
        AppLocale.duelDeclinedLabel,
      ),
    };
    final mine = duel.resultOf(uid);
    final theirs = duel.resultOf(duel.rivalOf(uid));
    return _DuelRow(
      icon: icon,
      iconColor: color,
      title: '${labelKey.getString(context)} $vs',
      subtitle: mine != null && theirs != null
          ? '${fill(points, mine.score)} – ${fill(points, theirs.score)}'
          : null,
      onTap: mine == null ? null : () => onPlay(duel),
    );
  }
}

class _DuelRow extends StatelessWidget {
  const _DuelRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                for (final action in actions) ...[
                  const SizedBox(width: 6),
                  action,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
