import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wraps [child] in a continuous, smooth up/down floating motion.
///
/// Used to make opposing elements (e.g. two versus avatars) feel alive
/// and to visually separate them from static UI chrome. [phase] shifts
/// the oscillation (0..1) so multiple instances can bob out of sync.
class FloatingBob extends StatefulWidget {
  const FloatingBob({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.duration = const Duration(seconds: 2),
    this.phase = 0,
  });

  final Widget child;
  final double amplitude;
  final Duration duration;
  final double phase;

  @override
  State<FloatingBob> createState() => _FloatingBobState();
}

class _FloatingBobState extends State<FloatingBob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..value = widget.phase
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offset =
            math.sin(_controller.value * 2 * math.pi) * widget.amplitude;
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: widget.child,
    );
  }
}
