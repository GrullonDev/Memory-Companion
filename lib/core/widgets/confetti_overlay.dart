import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Continuous confetti rain used behind celebratory overlays. Pieces fall
/// from above the top edge and loop back once they clear the bottom, each
/// on its own speed/phase so the rain never looks mechanically uniform.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({
    super.key,
    this.pieceCount = 28,
    this.colors = const [
      Color(0xFFFFE16D),
      Color(0xFF00BDFD),
      Color(0xFF9B7BFF),
      Color(0xFF4CD97B),
      Color(0xFFFFB77D),
    ],
  });

  final int pieceCount;
  final List<Color> colors;

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _pieces = List.generate(widget.pieceCount, (_) {
      return _ConfettiPiece(
        dx: random.nextDouble(),
        phase: random.nextDouble(),
        fallSpeed: 0.6 + random.nextDouble() * 0.8,
        drift: (random.nextDouble() - 0.5) * 40,
        size: 6 + random.nextDouble() * 6,
        spin: (random.nextDouble() - 0.5) * 8,
        color: widget.colors[random.nextInt(widget.colors.length)],
      );
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: [
                  for (final piece in _pieces)
                    _buildPiece(piece, width, height, _controller.value),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPiece(
    _ConfettiPiece piece,
    double width,
    double height,
    double t,
  ) {
    final progress = (t * piece.fallSpeed + piece.phase) % 1.0;
    final top = -40 + progress * (height + 80);
    final left =
        (piece.dx * width + piece.drift * math.sin(progress * math.pi * 2))
            .clamp(0, width - piece.size);
    final angle = progress * piece.spin * math.pi;

    return Positioned(
      top: top,
      left: left.toDouble(),
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: piece.size,
          height: piece.size * 0.6,
          decoration: BoxDecoration(
            color: piece.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.dx,
    required this.phase,
    required this.fallSpeed,
    required this.drift,
    required this.size,
    required this.spin,
    required this.color,
  });

  final double dx;
  final double phase;
  final double fallSpeed;
  final double drift;
  final double size;
  final double spin;
  final Color color;
}
