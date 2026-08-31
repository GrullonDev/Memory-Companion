import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:memory_companion/core/theme/app_motion.dart';

/// The app's single press interaction.
///
/// A tap does three things at once, in under 100ms: the surface scales down,
/// travels a few pixels toward the screen, and its shadow flattens. Together
/// they read as a physical button being pushed — feedback a 4-year-old
/// understands without being taught, and confirmation an older player gets
/// even if they don't feel the haptic.
///
/// This replaces `InkWell`, whose ripple is close to invisible on the
/// saturated fills this app uses, and bare `GestureDetector`, which gives no
/// feedback at all.
///
/// Honours the platform's "reduce motion" setting: when animations are
/// disabled the transform is skipped and only the shadow change remains.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.scale = AppMotion.pressScale,
    this.depth = AppMotion.pressDepth,
    this.shadow,
    this.pressedShadow,
    this.enabled = true,
    this.haptic = true,
    this.semanticLabel,
    this.semanticHint,
  });

  /// Convenience constructor for small controls (chips, nav items), which
  /// need a deeper scale to stay perceptible at their size.
  const Pressable.small({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.shadow,
    this.pressedShadow,
    this.enabled = true,
    this.haptic = true,
    this.semanticLabel,
    this.semanticHint,
  })  : scale = AppMotion.pressScaleSmall,
        depth = 0.0;

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;

  /// Scale reached at full press. 1.0 disables the scale.
  final double scale;

  /// Downward travel at full press, in logical pixels.
  final double depth;

  /// Resting shadow. Drawn by [Pressable] so it can flatten on press.
  final List<BoxShadow>? shadow;

  /// Shadow at full press. Defaults to [shadow] if omitted.
  final List<BoxShadow>? pressedShadow;

  final bool enabled;
  final bool haptic;

  /// Announced by screen readers. Pass this whenever the visible label is an
  /// icon or is shorter than what the control actually does.
  final String? semanticLabel;
  final String? semanticHint;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!_interactive || widget.onTap == null) return;
    if (widget.haptic) HapticFeedback.selectionClick();
    widget.onTap!.call();
  }

  void _handleLongPress() {
    if (!_interactive || widget.onLongPress == null) return;
    if (widget.haptic) HapticFeedback.mediumImpact();
    widget.onLongPress!.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final target = _pressed ? 1.0 : 0.0;
    final resting = widget.shadow;
    final pressedShadow = widget.pressedShadow ?? resting;

    return Semantics(
      button: _interactive,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _interactive ? _handleTap : null,
        onLongPress: widget.onLongPress == null ? null : _handleLongPress,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: _pressed ? AppMotion.instant : AppMotion.fast,
          curve: AppMotion.press,
          builder: (context, t, child) {
            final decorated = resting == null && pressedShadow == null
                ? child!
                : DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      boxShadow: BoxShadow.lerpList(
                        resting ?? const <BoxShadow>[],
                        pressedShadow ?? const <BoxShadow>[],
                        t,
                      ),
                    ),
                    child: child,
                  );

            if (reduceMotion) return decorated;

            final scale = 1 - (1 - widget.scale) * t;
            return Transform.translate(
              offset: Offset(0, widget.depth * t),
              child: Transform.scale(scale: scale, child: decorated),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}
