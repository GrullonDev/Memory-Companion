import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Center "VS" emblem: two dashed rings around a solid yellow circle,
/// flanked by a blue bolt (player side) and a red bolt (rival side).
class VsBadge extends StatelessWidget {
  const VsBadge({super.key});

  static const double _diameter = 132;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.bolt_rounded,
          color: AppColors.secondaryContainer,
          size: 32,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: _diameter,
          height: _diameter,
          child: CustomPaint(
            painter: _DashedRingsPainter(),
            child: Center(
              child: Container(
                width: _diameter * 0.66,
                height: _diameter * 0.66,
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixedDim,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40E6B400),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'VS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.onPrimaryFixed,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.bolt_rounded, color: AppColors.error, size: 32),
      ],
    );
  }
}

class _DashedRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    _drawDashedCircle(
      canvas,
      center,
      size.shortestSide / 2,
      AppColors.secondaryContainer,
    );
    _drawDashedCircle(
      canvas,
      center,
      size.shortestSide / 2 - 10,
      AppColors.primaryFixedDim,
    );
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const dashCount = 24;
    const dashFraction = 0.6;
    final anglePerDash = (2 * math.pi) / dashCount;

    for (var i = 0; i < dashCount; i++) {
      final startAngle = i * anglePerDash;
      final sweep = anglePerDash * dashFraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingsPainter oldDelegate) => false;
}
