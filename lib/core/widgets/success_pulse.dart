import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';

/// The "that was right" beat: pops [child] and flashes a soft glow behind
/// it each time [trigger] changes to a new non-null value — a pair matched,
/// a word found, an answer correct.
///
/// The pop peaks inside the 200ms feedback budget and settles within
/// [AppMotion.celebrate]. It animates scale and a shadow only, so nothing
/// around it reflows.
///
/// Honours the platform's "reduce motion" setting (the accessible profile
/// turns it on): the pop is skipped and only the glow fades in and out.
class SuccessPulse extends StatefulWidget {
  const SuccessPulse({
    super.key,
    required this.trigger,
    required this.child,
    this.color = AppColors.mint,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.playOnMount = false,
    this.haptic = false,
  });

  /// Plays whenever this changes to a new non-null value. Null means "no
  /// success to show", so a widget can pass `isMatched ? id : null`.
  final Object? trigger;
  final Widget child;

  /// Colour of the glow behind [child].
  final Color color;

  /// Shape of the glow; match the child's own corners.
  final BorderRadius? borderRadius;
  final BoxShape shape;

  /// Also plays on the first build when [trigger] is already non-null — for
  /// feedback widgets that only exist while there is something to show.
  final bool playOnMount;

  /// A light tap on devices with haptics, as the pulse starts.
  final bool haptic;

  @override
  State<SuccessPulse> createState() => _SuccessPulseState();
}

class _SuccessPulseState extends State<SuccessPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.celebrate,
  );

  // Up fast (≈150ms) and settle with a gentle overshoot.
  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.12,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 22,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.12,
        end: 1.0,
      ).chain(CurveTween(curve: AppMotion.settle)),
      weight: 78,
    ),
  ]);

  static final _glow = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 80,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    if (widget.playOnMount && widget.trigger != null) {
      // After the first frame, so the pop starts from the settled size.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  @override
  void didUpdateWidget(SuccessPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      _play();
    }
  }

  void _play() {
    if (widget.haptic) HapticFeedback.lightImpact();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      // The tree has the same shape whether or not the pulse is playing, so
      // starting one never remounts the child (and whatever state it holds).
      builder: (context, child) {
        final t = _controller.value;
        final glow = _controller.isAnimating ? _glow.transform(t) : 0.0;
        final decorated = DecoratedBox(
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : widget.borderRadius,
            boxShadow: glow == 0
                ? null
                : [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.55 * glow),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: child,
        );
        final scale = reduceMotion || !_controller.isAnimating
            ? 1.0
            : _scale.transform(t);
        return Transform.scale(scale: scale, child: decorated);
      },
    );
  }
}
