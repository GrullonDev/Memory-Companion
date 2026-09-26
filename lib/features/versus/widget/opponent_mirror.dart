import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';
import 'package:memory_companion/features/versus/widget/duel_presence_bar.dart';

/// Plays once per new rival report: [DuelProgress.seq] grows with every
/// event, so a repeated snapshot never replays its animation.
mixin _RivalEventListener<T extends StatefulWidget> on State<T> {
  DuelProgress? get rivalProgress;

  /// The newest report already accounted for. Null until the first check:
  /// whatever was there when the widget appeared is history, not news.
  int? _lastSeq;

  void onRivalEvent(DuelProgress progress);

  void checkRivalEvent() {
    final progress = rivalProgress;
    final last = _lastSeq;
    if (last == null) {
      _lastSeq = progress?.seq ?? 0;
      return;
    }
    if (progress == null || progress.seq <= last) return;
    _lastSeq = progress.seq;
    if (progress.event != DuelEvent.none) onRivalEvent(progress);
  }
}

/// A floating thumbnail of the rival's round, over the player's own game.
///
/// On the memory board it is a ghost of the same board: the rival's
/// matched cards fill in, a pair they match pops green and a pair they
/// miss shakes red before covering again. On the other games it is a ring
/// of their progress that flashes with every answer. Tapping it switches
/// between the full thumbnail and a compact badge.
class OpponentMirror extends StatefulWidget {
  const OpponentMirror({
    super.key,
    required this.game,
    required this.rivalName,
    required this.progress,
    required this.live,
    this.cardCount = Duel.pairCount * 2,
    this.finishedScore,
    this.initiallyExpanded = true,
  });

  final DuelGame game;
  final String rivalName;

  /// Their latest report for this round, if any.
  final DuelProgress? progress;

  /// Whether they are playing right now.
  final bool live;
  final int cardCount;

  /// Their result for this round, once they finished it.
  final int? finishedScore;
  final bool initiallyExpanded;

  @override
  State<OpponentMirror> createState() => _OpponentMirrorState();
}

class _OpponentMirrorState extends State<OpponentMirror>
    with SingleTickerProviderStateMixin, _RivalEventListener {
  late bool _expanded = widget.initiallyExpanded;

  /// Runs once per rival event: pop for a hit, shake for a miss.
  late final AnimationController _flash = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  DuelEvent _flashEvent = DuelEvent.none;
  List<int> _flashCards = const [];

  @override
  DuelProgress? get rivalProgress => widget.progress;

  @override
  void initState() {
    super.initState();
    checkRivalEvent();
  }

  @override
  void didUpdateWidget(OpponentMirror oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkRivalEvent();
  }

  @override
  void onRivalEvent(DuelProgress progress) {
    setState(() {
      _flashEvent = progress.event;
      _flashCards = progress.cards;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _flash.value = 1;
    } else {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  Color get _eventColor => switch (_flashEvent) {
    DuelEvent.hit => AppColors.mintDeep,
    DuelEvent.miss => AppColors.error,
    DuelEvent.none => AppColors.outline,
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = widget.progress;
    final finished = widget.finishedScore;
    final status = finished != null
        ? AppLocale.rivalRoundFinal
              .getString(context)
              .replaceAll('{points}', '$finished')
        : widget.live
        ? '${progress?.score ?? 0} pts'
        : AppLocale.rivalNotPlayingNow.getString(context);

    return Semantics(
      button: true,
      hint: AppLocale.mirrorExpandHint.getString(context),
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: AnimatedBuilder(
          animation: _flash,
          builder: (context, child) {
            // The frame glows in the event's colour, fading as it settles.
            final glow = _flash.isAnimating ? 1 - _flash.value : 0.0;
            return Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Color.lerp(
                    AppColors.error.withValues(alpha: 0.35),
                    _eventColor,
                    glow,
                  )!,
                  width: 2 + glow * 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _eventColor.withValues(alpha: 0.35 * glow),
                    blurRadius: 18 * glow,
                  ),
                  const BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              width: _expanded ? 128 : 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      PlayerFace(
                        name: widget.rivalName,
                        color: AppColors.error,
                        size: 26,
                      ),
                      if (_expanded) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.rivalName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      if (widget.live)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: _LiveDot(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (widget.game == DuelGame.memory)
                    _GhostBoard(
                      cardCount: widget.cardCount,
                      matched: progress?.matched ?? const [],
                      flashCards: _flashCards,
                      flashEvent: _flashEvent,
                      flash: _flash,
                    )
                  else
                    _ProgressRing(
                      fraction: progress?.fraction ?? 0,
                      label: progress == null
                          ? '–'
                          : '${progress.solved}/${progress.total}',
                      color: _eventColor,
                      flash: _flash,
                    ),
                  if (_expanded) ...[
                    const SizedBox(height: 6),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rival's board, face down and faint: only what they did shows.
class _GhostBoard extends StatelessWidget {
  const _GhostBoard({
    required this.cardCount,
    required this.matched,
    required this.flashCards,
    required this.flashEvent,
    required this.flash,
  });

  final int cardCount;
  final List<int> matched;
  final List<int> flashCards;
  final DuelEvent flashEvent;
  final Animation<double> flash;

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flash,
      builder: (context, _) {
        final t = flash.value;
        final running = flash.isAnimating;
        return GridView.count(
          crossAxisCount: _columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          childAspectRatio: 0.8,
          children: [
            for (var i = 0; i < cardCount; i++)
              _ghostCard(
                isMatched: matched.contains(i),
                isFlashing: running && flashCards.contains(i),
                t: t,
              ),
          ],
        );
      },
    );
  }

  Widget _ghostCard({
    required bool isMatched,
    required bool isFlashing,
    required double t,
  }) {
    var color = isMatched
        ? AppColors.mint
        : AppColors.surfaceContainerHigh.withValues(alpha: 0.55);
    var dx = 0.0;
    var scale = 1.0;
    if (isFlashing) {
      if (flashEvent == DuelEvent.hit) {
        // Pop, then settle into the matched colour.
        scale = 1 + 0.35 * math.sin(t * math.pi);
        color = Color.lerp(AppColors.sun, AppColors.mint, t)!;
      } else if (flashEvent == DuelEvent.miss) {
        // Face up in red, shake, then cover again: the same beat as the
        // board's own mismatch pause.
        dx = math.sin(t * math.pi * 6) * 3 * (1 - t);
        color = Color.lerp(
          AppColors.error,
          AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
          Curves.easeIn.transform(t),
        )!;
      }
    }
    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.fraction,
    required this.label,
    required this.color,
    required this.flash,
  });

  final double fraction;
  final String label;
  final Color color;
  final Animation<double> flash;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flash,
      builder: (context, child) => Transform.scale(
        scale: flash.isAnimating
            ? 1 + 0.12 * math.sin(flash.value * math.pi)
            : 1,
        child: child,
      ),
      child: SizedBox.square(
        dimension: 52,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                color: AppColors.error,
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
            ),
            Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
      opacity: Tween<double>(begin: 1, end: 0.3).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.mintDeep,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A short banner for each rival hit or miss, slid in under the face-off
/// so the player feels every move of the rival without looking away.
class RivalEventBanner extends StatefulWidget {
  const RivalEventBanner({
    super.key,
    required this.progress,
    required this.rivalName,
    required this.game,
  });

  final DuelProgress? progress;
  final String rivalName;
  final DuelGame game;

  /// How long each banner stays.
  static const visibleFor = Duration(milliseconds: 1600);

  @override
  State<RivalEventBanner> createState() => _RivalEventBannerState();
}

class _RivalEventBannerState extends State<RivalEventBanner>
    with _RivalEventListener {
  DuelEvent _event = DuelEvent.none;
  int _shown = 0;
  Timer? _hide;

  @override
  DuelProgress? get rivalProgress => widget.progress;

  @override
  void initState() {
    super.initState();
    checkRivalEvent();
  }

  @override
  void didUpdateWidget(RivalEventBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    checkRivalEvent();
  }

  @override
  void onRivalEvent(DuelProgress progress) {
    setState(() {
      _shown++;
      _event = progress.event;
    });
    _hide?.cancel();
    _hide = Timer(RivalEventBanner.visibleFor, () {
      if (mounted) setState(() => _event = DuelEvent.none);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.game == DuelGame.memory;
    final (key, color, icon) = switch (_event) {
      DuelEvent.hit => (
        board ? AppLocale.rivalHitPair : AppLocale.rivalHitAnswer,
        AppColors.error,
        Icons.bolt_rounded,
      ),
      DuelEvent.miss => (
        board ? AppLocale.rivalMissPair : AppLocale.rivalMissAnswer,
        AppColors.mintDeep,
        Icons.close_rounded,
      ),
      DuelEvent.none => (null, AppColors.outline, Icons.circle),
    };

    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.6),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: key == null
            ? const SizedBox.shrink()
            : Container(
                key: ValueKey(_shown),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      key
                          .getString(context)
                          .replaceAll('{name}', widget.rivalName),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
