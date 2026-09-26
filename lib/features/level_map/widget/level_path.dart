import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/success_pulse.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';
import 'package:memory_companion/features/level_map/widget/level_node_tile.dart';

/// Winding level path: a dashed spine with level nodes alternating left
/// and right, level 1 at the bottom climbing up to the highest level.
class LevelPath extends StatelessWidget {
  const LevelPath({
    super.key,
    required this.levels,
    required this.onSelectLevel,
    this.currentNodeKey,
    this.focusPulse,
  });

  final List<LevelNode> levels;
  final ValueChanged<LevelNode> onSelectLevel;

  /// Attached to the current node, so the map can scroll to it.
  final GlobalKey? currentNodeKey;

  /// Pulses the current node each time it changes to a new non-null value:
  /// the "you are here" beat after the map scrolls back to it.
  final Object? focusPulse;

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
                child: _node(levels[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _node(LevelNode node) {
    final isCurrent = node.status == LevelStatus.current;
    final reward = node.status == LevelStatus.completed
        ? null
        : LevelRewards.forCompletedLevel(node.number);
    Widget tile = LevelNodeTile(node: node, onTap: () => onSelectLevel(node));
    if (reward != null) {
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            top: -8,
            right: -8,
            child: _RewardMarker(isChest: reward.isChest),
          ),
        ],
      );
    }
    if (!isCurrent) return tile;
    return SuccessPulse(
      key: currentNodeKey,
      trigger: focusPulse,
      color: AppColors.primaryFixedDim,
      borderRadius: BorderRadius.circular(20),
      haptic: true,
      child: tile,
    );
  }
}

/// Marks a node whose completion pays a ladder reward.
class _RewardMarker extends StatelessWidget {
  const _RewardMarker({required this.isChest});

  final bool isChest;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.sun,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceContainerLowest, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isChest ? Icons.inventory_2_rounded : Icons.card_giftcard_rounded,
          size: 16,
          color: AppColors.onSun,
        ),
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
