import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/versus/model/duel_reaction.dart';
import 'package:memory_companion/features/versus/widget/duel_presence_bar.dart';

extension DuelReactionLabel on DuelReaction {
  /// What a screen reader says for the emoji.
  String get labelKey => switch (this) {
    DuelReaction.thumbsUp => AppLocale.reactionThumbsUp,
    DuelReaction.fire => AppLocale.reactionFire,
    DuelReaction.wow => AppLocale.reactionWow,
    DuelReaction.laugh => AppLocale.reactionLaugh,
  };
}

/// Floats an emoji up from [child] every time [event] carries a new
/// [DuelReactionEvent.seq]: over the rival's thumbnail for theirs, over the
/// player's own picker as an echo of what they sent.
///
/// Like the rival's hits and misses, whatever was there when the widget
/// appeared is history: only reactions that arrive afterwards float.
class FloatingReactions extends StatefulWidget {
  const FloatingReactions({
    super.key,
    required this.event,
    required this.child,
    this.senderName,
    this.alignment = Alignment.center,
    this.rise = 84,
  });

  final DuelReactionEvent? event;
  final Widget child;

  /// Who sent them, for the screen reader. Null for the player's own.
  final String? senderName;

  /// Where on [child] the bubbles start.
  final Alignment alignment;

  /// How far they climb, in logical pixels.
  final double rise;

  /// How long each bubble stays.
  static const lifetime = Duration(milliseconds: 1800);

  /// Bubbles on screen at once; a burst beyond this drops the oldest.
  static const maxBubbles = 6;

  @override
  State<FloatingReactions> createState() => _FloatingReactionsState();
}

class _FloatingReactionsState extends State<FloatingReactions>
    with TickerProviderStateMixin {
  /// Taken in [initState], not lazily: a lazy field would first be read in
  /// [didUpdateWidget], already holding the new event, and swallow it.
  late int _lastSeq;
  final _bubbles = <_Bubble>[];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _lastSeq = widget.event?.seq ?? 0;
  }

  @override
  void didUpdateWidget(FloatingReactions oldWidget) {
    super.didUpdateWidget(oldWidget);
    final event = widget.event;
    if (event == null || event.seq <= _lastSeq) return;
    _lastSeq = event.seq;
    _spawn(event.reaction);
  }

  void _spawn(DuelReaction reaction) {
    final controller = AnimationController(
      vsync: this,
      duration: FloatingReactions.lifetime,
    );
    final bubble = _Bubble(
      reaction: reaction,
      controller: controller,
      // A little sideways drift, so a burst fans out instead of stacking.
      drift: (_random.nextDouble() - 0.5) * 36,
    );
    setState(() {
      _bubbles.add(bubble);
      if (_bubbles.length > FloatingReactions.maxBubbles) {
        _bubbles.removeAt(0).controller.dispose();
      }
    });
    // With animations off the bubble just sits there for its lifetime.
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) controller.value = 0.3;
    final done = reduced
        ? Future<void>.delayed(FloatingReactions.lifetime)
        : controller.forward().orCancel.catchError((_) {});
    done.whenComplete(() {
      if (!mounted || !_bubbles.remove(bubble)) return;
      setState(() {});
      bubble.controller.dispose();
    });
  }

  @override
  void dispose() {
    for (final bubble in _bubbles) {
      bubble.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sender = widget.senderName;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        for (final bubble in _bubbles)
          Positioned.fill(
            key: ObjectKey(bubble),
            child: IgnorePointer(
              child: Align(
                alignment: widget.alignment,
                child: Semantics(
                  liveRegion: sender != null,
                  label: sender == null
                      ? null
                      : AppLocale.reactionFromRival
                            .getString(context)
                            .replaceAll('{name}', sender)
                            .replaceAll(
                              '{reaction}',
                              bubble.reaction.labelKey.getString(context),
                            ),
                  child: ExcludeSemantics(
                    child: _FloatingEmoji(bubble: bubble, rise: widget.rise),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble {
  _Bubble({
    required this.reaction,
    required this.controller,
    required this.drift,
  });

  final DuelReaction reaction;
  final AnimationController controller;
  final double drift;
}

class _FloatingEmoji extends StatelessWidget {
  const _FloatingEmoji({required this.bubble, required this.rise});

  final _Bubble bubble;
  final double rise;

  /// Pops in past full size, then settles: the first fifth of the flight.
  static final _pop = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.3,
        end: 1.35,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 20,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1), weight: 15),
    TweenSequenceItem(tween: ConstantTween(1), weight: 65),
  ]);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bubble.controller,
      builder: (context, child) {
        final t = bubble.controller.value;
        final climb = Curves.easeOutCubic.transform(t);
        // Fully visible for most of the way, fading over the last 40%.
        final opacity = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
        return Transform.translate(
          offset: Offset(
            bubble.drift * climb + math.sin(t * math.pi * 3) * 4,
            -rise * climb,
          ),
          child: Transform.scale(
            scale: _pop.transform(t),
            child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: child),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          bubble.reaction.emoji,
          style: const TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

/// The player's quick reactions while a round is played: a small round
/// button that opens into the emoji tray, so it never covers the board for
/// longer than it takes to pick one.
class ReactionPicker extends StatefulWidget {
  const ReactionPicker({
    super.key,
    required this.onReact,
    this.coolingDown = false,
    this.direction = Axis.vertical,
  });

  final ValueChanged<DuelReaction> onReact;

  /// Dims the emojis right after a send, while more would be ignored.
  final bool coolingDown;

  /// Which way the tray opens.
  final Axis direction;

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  bool _open = false;

  void _pick(DuelReaction reaction) {
    widget.onReact(reaction);
    setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final toggle = _RoundButton(
      tooltip: AppLocale.reactionsButtonLabel.getString(context),
      onTap: () => setState(() => _open = !_open),
      child: Icon(
        _open ? Icons.close_rounded : Icons.add_reaction_rounded,
        color: AppColors.primary,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topLeft,
        child: Flex(
          direction: widget.direction,
          mainAxisSize: MainAxisSize.min,
          children: [
            toggle,
            if (_open)
              for (final reaction in DuelReaction.values)
                _EmojiButton(
                  reaction: reaction,
                  enabled: !widget.coolingDown,
                  onTap: () => _pick(reaction),
                ),
          ],
        ),
      ),
    );
  }
}

/// Quick reactions between rounds and after the series: the rival's face
/// on one side, where their reactions float up, and the player's emojis on
/// the other, always open.
class ReactionBar extends StatelessWidget {
  const ReactionBar({
    super.key,
    required this.rivalName,
    required this.rivalReaction,
    required this.myReaction,
    required this.onReact,
    this.coolingDown = false,
  });

  final String rivalName;
  final DuelReactionEvent? rivalReaction;
  final DuelReactionEvent? myReaction;
  final ValueChanged<DuelReaction> onReact;
  final bool coolingDown;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          FloatingReactions(
            event: rivalReaction,
            senderName: rivalName,
            alignment: Alignment.topCenter,
            child: PlayerFace(
              name: rivalName,
              color: AppColors.error,
              size: 36,
            ),
          ),
          const Spacer(),
          FloatingReactions(
            event: myReaction,
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final reaction in DuelReaction.values)
                  _EmojiButton(
                    reaction: reaction,
                    enabled: !coolingDown,
                    onTap: () => onReact(reaction),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.reaction,
    required this.enabled,
    required this.onTap,
  });

  final DuelReaction reaction;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _RoundButton(
      tooltip: reaction.labelKey.getString(context),
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Text(reaction.emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

/// A round tap target of the app's minimum touch size.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: AppSize.touchMin,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
