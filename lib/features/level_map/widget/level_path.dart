import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';
import 'package:memory_companion/features/level_map/widget/level_node_tile.dart';

/// Winding level path: a dashed spine with level nodes alternating left
/// and right, level 1 at the bottom climbing up to the highest level.
class LevelPath extends StatelessWidget {
  const LevelPath({
    super.key,
    required this.levels,
    required this.onSelectLevel,
  });

  final List<LevelNode> levels;
  final ValueChanged<LevelNode> onSelectLevel;

  @override
  Widget build(BuildContext context) {
    const nodeSpacing = 150.0;
    final height = levels.length * nodeSpacing;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned(
            top: nodeSpacing / 2,
            bottom: nodeSpacing / 2,
            left: 0,
            right: 0,
            child: CustomPaint(painter: const _DashedSpinePainter()),
          ),
          for (var i = 0; i < levels.length; i++)
            Positioned(
              bottom: i * nodeSpacing,
              left: 0,
              right: 0,
              child: Align(
                alignment: i.isEven
                    ? const Alignment(-0.5, 0)
                    : const Alignment(0.5, 0),
                child: LevelNodeTile(
                  node: levels[i],
                  onTap: () => onSelectLevel(levels[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedSpinePainter extends CustomPainter {
  const _DashedSpinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceContainerHighest
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    const dashHeight = 14.0;
    const dashGap = 10.0;
    var y = 0.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashHeight),
        paint,
      );
      y += dashHeight + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSpinePainter oldDelegate) => false;
}
