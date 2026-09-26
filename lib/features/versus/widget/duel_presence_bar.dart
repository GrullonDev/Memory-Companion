import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/versus/model/duel.dart';

/// The face-off above a duel: both players, the rounds each has won, and
/// what the rival is doing right now. Makes it plain the match is against
/// a person, even when they play at another time.
class DuelPresenceBar extends StatelessWidget {
  const DuelPresenceBar({
    super.key,
    required this.duel,
    required this.uid,
    required this.myName,
    required this.rivalName,
    this.rivalStatus,
    this.round,
    this.myProgress,
  });

  final Duel duel;
  final String uid;
  final String myName;
  final String rivalName;

  /// Their presence as a friend; null for a room with a stranger.
  final FriendStatus? rivalStatus;

  /// The round being played on this device, if any.
  final int? round;

  /// Where this player stands in [round], as last reported.
  final DuelProgress? myProgress;

  /// The rival's report for [round], while they are playing it now.
  DuelProgress? get rivalLive {
    final progress = duel.progress[duel.rivalOf(uid)];
    if (progress == null || progress.round != round) return null;
    return progress.isLive(DateTime.now()) ? progress : null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rivalUid = duel.rivalOf(uid);
    final round = this.round;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _Side(
                  name: myName,
                  wins: duel.winsOf(uid),
                  winsNeeded: duel.winsNeeded,
                  color: AppColors.secondaryContainer,
                  score: myProgress?.score ?? (round == null ? null : 0),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${duel.winsOf(uid)} - ${duel.winsOf(rivalUid)}',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (round != null)
                    Text(
                      AppLocale.roundOfLabel
                          .getString(context)
                          .replaceAll('{n}', '${round + 1}')
                          .replaceAll('{total}', '${duel.rounds}'),
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              Expanded(
                child: _Side(
                  name: rivalName,
                  wins: duel.winsOf(rivalUid),
                  winsNeeded: duel.winsNeeded,
                  color: AppColors.error,
                  score: round == null
                      ? null
                      : duel.scoreOf(rivalUid, round)?.score ??
                            rivalLive?.score,
                  reversed: true,
                ),
              ),
            ],
          ),
          if (round != null) ...[
            const SizedBox(height: AppSpacing.sm),
            // The race: both progress bars side by side, in step with every
            // pair or answer either player gets.
            _RaceBar(progress: myProgress, color: AppColors.secondaryContainer),
            const SizedBox(height: 4),
            _RaceBar(
              progress: duel.scoreOf(rivalUid, round) != null
                  ? const DuelProgress(round: 0, score: 0, solved: 1, total: 1)
                  : rivalLive,
              color: AppColors.error,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          RivalActivity(duel: duel, rivalUid: rivalUid, status: rivalStatus),
        ],
      ),
    );
  }
}

/// One lane of the race. Flashes red on a miss and gold on a hit, so a
/// slip or a pair is felt the instant it happens — on either side.
class _RaceBar extends StatefulWidget {
  const _RaceBar({required this.progress, required this.color});

  final DuelProgress? progress;
  final Color color;

  @override
  State<_RaceBar> createState() => _RaceBarState();
}

class _RaceBarState extends State<_RaceBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  int _seq = -1;
  DuelEvent _event = DuelEvent.none;

  @override
  void didUpdateWidget(_RaceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final progress = widget.progress;
    if (progress == null) return;
    if (progress.seq > _seq && progress.event != DuelEvent.none) {
      _event = progress.event;
      if (!MediaQuery.disableAnimationsOf(context)) _flash.forward(from: 0);
    }
    _seq = progress.seq;
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashColor = _event == DuelEvent.miss
        ? AppColors.error
        : AppColors.sun;
    return AnimatedBuilder(
      animation: _flash,
      builder: (context, _) {
        final glow = _flash.isAnimating ? 1 - _flash.value : 0.0;
        return TweenAnimationBuilder<double>(
          tween: Tween(end: widget.progress?.fraction ?? 0),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6 + glow * 3,
              color: Color.lerp(widget.color, flashColor, glow),
              backgroundColor: Color.lerp(
                AppColors.surfaceContainerHigh,
                flashColor.withValues(alpha: 0.35),
                glow,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({
    required this.name,
    required this.wins,
    required this.winsNeeded,
    required this.color,
    this.score,
    this.reversed = false,
  });

  final String name;
  final int wins;
  final int winsNeeded;
  final Color color;
  final int? score;
  final bool reversed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final score = this.score;
    final info = Flexible(
      child: Column(
        crossAxisAlignment: reversed
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < winsNeeded; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 3, top: 3),
                  child: Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: i < wins ? AppColors.sunDeep : AppColors.outline,
                  ),
                ),
            ],
          ),
          if (score != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '$score pts',
                key: ValueKey(score),
                style: textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
    final children = [
      PlayerFace(name: name, color: color),
      const SizedBox(width: AppSpacing.sm),
      info,
    ];
    return Row(
      mainAxisAlignment: reversed
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: reversed ? children.reversed.toList() : children,
    );
  }
}

/// A round avatar with the player's initials, ringed in their side's colour.
class PlayerFace extends StatelessWidget {
  const PlayerFace({
    super.key,
    required this.name,
    required this.color,
    this.size = 44,
  });

  final String name;
  final Color color;
  final double size;

  String get _initials {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.single;
      return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: CircleAvatar(
        backgroundColor: AppColors.surfaceContainerLowest,
        child: Text(
          _initials,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}

/// One line on what the rival is up to: playing a round right now, how
/// many rounds they have played, or that they have not started.
class RivalActivity extends StatelessWidget {
  const RivalActivity({
    super.key,
    required this.duel,
    required this.rivalUid,
    this.status,
  });

  final Duel duel;
  final String rivalUid;
  final FriendStatus? status;

  @override
  Widget build(BuildContext context) {
    final progress = duel.progress[rivalUid];
    final played = [
      for (var round = 0; round < duel.rounds; round++)
        if (duel.scoreOf(rivalUid, round) != null) round,
    ].length;
    final live =
        progress != null &&
        progress.isLive(DateTime.now()) &&
        duel.scoreOf(rivalUid, progress.round) == null;

    final String text;
    final Color color;
    if (live) {
      text = AppLocale.rivalPlayingRound
          .getString(context)
          .replaceAll('{n}', '${progress.round + 1}')
          .replaceAll('{points}', '${progress.score}');
      color = AppColors.mintDeep;
    } else {
      text = played == 0
          ? AppLocale.rivalNotStarted.getString(context)
          : AppLocale.rivalRoundsPlayed
                .getString(context)
                .replaceAll('{n}', '$played')
                .replaceAll('{total}', '${duel.rounds}');
      color = switch (status) {
        FriendStatus.online => AppColors.mintDeep,
        FriendStatus.inGame => AppColors.sunDeep,
        FriendStatus.offline || null => AppColors.onSurfaceVariant,
      };
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PulsingDot(color: color, pulsing: live),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color, required this.pulsing});

  final Color color;
  final bool pulsing;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
