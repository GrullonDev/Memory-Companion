import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';

/// A single stop on the level path: locked (gray, padlock), current
/// (yellow, star) or completed (green, checkmark).
class LevelNodeTile extends StatelessWidget {
  const LevelNodeTile({super.key, required this.node, required this.onTap});

  final LevelNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (node.status) {
      LevelStatus.completed => (
        AppColors.mintGreen,
        AppColors.onMintGreen,
        Icons.check_rounded,
      ),
      LevelStatus.current => (
        AppColors.primaryFixedDim,
        AppColors.onPrimaryFixed,
        Icons.star_rounded,
      ),
      LevelStatus.locked => (
        AppColors.surfaceContainerHigh,
        AppColors.outline,
        Icons.lock_rounded,
      ),
    };

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      elevation: node.status == LevelStatus.current ? 6 : 2,
      shadowColor: const Color(0x40000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: node.isPlayable ? onTap : null,
        child: Container(
          width: 84,
          height: 84,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 28),
              const SizedBox(height: 4),
              Text(
                'Lvl ${node.number}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
