import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/confetti_overlay.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/widget/duel_presence_bar.dart';
import 'package:memory_companion/features/versus/widget/opponent_mirror.dart';

/// A duel between rounds: the face-off, the series score round by round,
/// and what comes next — the next round, waiting for the rival, or the
/// final result with a rematch.
class DuelSeriesView extends StatelessWidget {
  const DuelSeriesView({
    super.key,
    required this.duel,
    required this.uid,
    required this.myName,
    required this.rivalName,
    required this.onPlayRound,
    required this.onRematch,
    required this.onExit,
    this.rivalStatus,
    this.submitFailed = false,
    this.rematchBusy = false,
  });

  final Duel duel;
  final String uid;
  final String myName;
  final String rivalName;
  final FriendStatus? rivalStatus;
  final bool submitFailed;
  final bool rematchBusy;
  final ValueChanged<int> onPlayRound;
  final VoidCallback onRematch;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rivalUid = duel.rivalOf(uid);
    final outcome = duel.outcomeFor(uid);
    final nextRound = duel.nextRoundFor(uid);
    final declined = duel.status == DuelStatus.declined;

    final (titleKey, messageKey, color, icon) = switch (outcome) {
      DuelOutcome.won => (
        AppLocale.seriesVictoryTitle,
        AppLocale.seriesVictoryMessage,
        AppColors.sunDeep,
        Icons.emoji_events_rounded,
      ),
      DuelOutcome.lost => (
        AppLocale.seriesDefeatTitle,
        AppLocale.seriesDefeatMessage,
        AppColors.error,
        Icons.sentiment_dissatisfied_rounded,
      ),
      DuelOutcome.draw => (
        AppLocale.seriesDrawTitle,
        AppLocale.seriesDefeatMessage,
        AppColors.skyStrong,
        Icons.handshake_rounded,
      ),
      null when declined => (
        AppLocale.duelDeclinedLabel,
        null,
        AppColors.onSurfaceVariant,
        Icons.block_rounded,
      ),
      null when nextRound == null => (
        AppLocale.seriesWaitingTitle,
        AppLocale.seriesWaitingMessage,
        AppColors.onSurfaceVariant,
        Icons.hourglass_top_rounded,
      ),
      null => (
        AppLocale.seriesInProgressTitle,
        AppLocale.bestOfThreeLabel,
        AppColors.skyStrong,
        Icons.sports_esports_rounded,
      ),
    };

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Center(
              child: Chip(
                avatar: Icon(
                  duel.game.icon,
                  color: duel.game.palette.foreground,
                ),
                label: Text(duel.game.titleKey.getString(context)),
                labelStyle: textTheme.labelLarge?.copyWith(
                  color: duel.game.palette.foreground,
                  fontWeight: FontWeight.w800,
                ),
                backgroundColor: duel.game.palette.background,
                side: BorderSide.none,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Icon(icon, size: 72, color: color),
            ),
            Text(
              titleKey.getString(context).replaceAll('{name}', rivalName),
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (messageKey != null)
              Text(
                messageKey.getString(context),
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            _FaceOff(
              myName: myName,
              rivalName: rivalName,
              myWins: duel.winsOf(uid),
              rivalWins: duel.winsOf(rivalUid),
            ),
            const SizedBox(height: AppSpacing.md),
            RivalActivity(duel: duel, rivalUid: rivalUid, status: rivalStatus),
            if (_rivalLiveNow(rivalUid) case final live?) ...[
              const SizedBox(height: AppSpacing.lg),
              _WatchLive(duel: duel, progress: live, rivalName: rivalName),
            ],
            const SizedBox(height: AppSpacing.lg),
            _RoundTable(duel: duel, uid: uid, rivalName: rivalName),
            if (submitFailed) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocale.duelSubmitFailed.getString(context),
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            if (nextRound != null)
              FilledButton.icon(
                onPressed: () => onPlayRound(nextRound),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  AppLocale.playRoundLabel
                      .getString(context)
                      .replaceAll('{n}', '${nextRound + 1}'),
                ),
              )
            else if (outcome != null)
              FilledButton.icon(
                onPressed: rematchBusy ? null : onRematch,
                icon: rematchBusy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.replay_rounded),
                label: Text(AppLocale.rematchLabel.getString(context)),
              ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onExit,
              child: Text(AppLocale.backToHome.getString(context)),
            ),
          ],
        ),
        if (outcome == DuelOutcome.won)
          const Positioned.fill(child: ConfettiOverlay()),
      ],
    );
  }

  /// The rival's report while they are mid-round right now.
  DuelProgress? _rivalLiveNow(String rivalUid) {
    final progress = duel.progress[rivalUid];
    if (progress == null || !progress.isLive(DateTime.now())) return null;
    if (duel.scoreOf(rivalUid, progress.round) != null) return null;
    return progress;
  }
}

/// Spectating: the rival's round, move by move, between the player's own.
class _WatchLive extends StatelessWidget {
  const _WatchLive({
    required this.duel,
    required this.progress,
    required this.rivalName,
  });

  final Duel duel;
  final DuelProgress progress;
  final String rivalName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocale.watchRivalLive
              .getString(context)
              .replaceAll('{name}', rivalName),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RivalEventBanner(
          progress: progress,
          rivalName: rivalName,
          game: duel.game,
        ),
        const SizedBox(height: AppSpacing.sm),
        OpponentMirror(
          game: duel.game,
          rivalName: rivalName,
          progress: progress,
          live: true,
        ),
      ],
    );
  }
}

class _FaceOff extends StatelessWidget {
  const _FaceOff({
    required this.myName,
    required this.rivalName,
    required this.myWins,
    required this.rivalWins,
  });

  final String myName;
  final String rivalName;
  final int myWins;
  final int rivalWins;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget side(String name, Color color) => Expanded(
      child: Column(
        children: [
          PlayerFace(name: name, color: color, size: 64),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
    return Row(
      children: [
        side(myName, AppColors.secondaryContainer),
        Text(
          '$myWins - $rivalWins',
          style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        side(rivalName, AppColors.error),
      ],
    );
  }
}

class _RoundTable extends StatelessWidget {
  const _RoundTable({
    required this.duel,
    required this.uid,
    required this.rivalName,
  });

  final Duel duel;
  final String uid;
  final String rivalName;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rivalUid = duel.rivalOf(uid);
    final label = textTheme.labelMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );

    String points(DuelScore? score) => score == null ? '—' : '${score.score}';

    TableRow row(
      String title,
      String mine,
      String theirs,
      Widget status, {
      bool bold = false,
    }) {
      final style = textTheme.titleSmall?.copyWith(
        fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      );
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(title, style: style),
          ),
          Text(mine, textAlign: TextAlign.center, style: style),
          Text(theirs, textAlign: TextAlign.center, style: style),
          Align(alignment: Alignment.centerRight, child: status),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.4),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(1.4),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            children: [
              const SizedBox(height: 36),
              Text(
                AppLocale.youLabel.getString(context),
                textAlign: TextAlign.center,
                style: label,
              ),
              Text(
                rivalName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: label,
              ),
              const SizedBox.shrink(),
            ],
          ),
          for (var round = 0; round < duel.rounds; round++)
            row(
              AppLocale.roundOfLabel
                  .getString(context)
                  .replaceAll('{n}', '${round + 1}')
                  .replaceAll('{total}', '${duel.rounds}'),
              points(duel.scoreOf(uid, round)),
              points(duel.scoreOf(rivalUid, round)),
              _RoundStatus(duel: duel, uid: uid, round: round),
            ),
          row(
            AppLocale.totalPointsLabel.getString(context),
            points(duel.resultOf(uid)),
            points(duel.resultOf(rivalUid)),
            const SizedBox.shrink(),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _RoundStatus extends StatelessWidget {
  const _RoundStatus({
    required this.duel,
    required this.uid,
    required this.round,
  });

  final Duel duel;
  final String uid;
  final int round;

  @override
  Widget build(BuildContext context) {
    final winner = duel.roundWinner(round);
    final skipped =
        winner == null &&
        duel.isDecided &&
        (duel.scoreOf(uid, round) == null ||
            duel.scoreOf(duel.rivalOf(uid), round) == null);
    final (text, color) = switch (winner) {
      _ when skipped => (
        AppLocale.roundNotNeededLabel,
        AppColors.onSurfaceVariant,
      ),
      null => (AppLocale.roundPendingLabel, AppColors.onSurfaceVariant),
      '' => (AppLocale.roundTiedLabel, AppColors.skyStrong),
      _ when winner == uid => (AppLocale.duelWonLabel, AppColors.mintDeep),
      _ => (AppLocale.duelLostLabel, AppColors.error),
    };
    return Text(
      text.getString(context),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
