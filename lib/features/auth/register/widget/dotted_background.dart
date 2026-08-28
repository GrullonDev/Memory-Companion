import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Sparse dot-grid backdrop used behind the register screen.
class DottedBackground extends StatelessWidget {
  const DottedBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _DotGridPainter(), child: child);
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const double _spacing = 28;
  static const double _radius = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.outlineVariant.withValues(alpha: 0.5);
    for (double y = 0; y < size.height; y += _spacing) {
      for (double x = 0; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), _radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
