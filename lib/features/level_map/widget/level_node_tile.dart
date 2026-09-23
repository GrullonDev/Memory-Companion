import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';

/// A single stop on the level path: locked (gray, padlock), current
/// (yellow, star) or completed (green, checkmark).
///
/// Status is carried by the icon as well as the color, and read out as one
/// label ("Level 3, locked"). The accessible profile adds a solid outline.
class LevelNodeTile extends StatelessWidget {
  const LevelNodeTile({super.key, required this.node, required this.onTap});

  static const _size = 84.0;

  final LevelNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final (background, foreground, icon, statusKey) = switch (node.status) {
      LevelStatus.completed => (
        AppColors.mintGreen,
        AppColors.onMintGreen,
        Icons.check_rounded,
        AppLocale.levelNodeCompleted,
      ),
      LevelStatus.current => (
        AppColors.primaryFixedDim,
        AppColors.onPrimaryFixed,
        Icons.star_rounded,
        AppLocale.levelNodeCurrent,
      ),
      LevelStatus.locked => (
        AppColors.surfaceContainerHigh,
        AppColors.outline,
        Icons.lock_rounded,
        AppLocale.levelNodeLocked,
      ),
    };
    final isCurrent = node.status == LevelStatus.current;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: tokens.buttonBorderWidth == 0
          ? BorderSide.none
          : BorderSide(
              color: isCurrent ? AppColors.onPrimaryFixed : tokens.outlineColor,
              width: tokens.buttonBorderWidth,
            ),
    );
    final levelLabel = AppLocale.levelLabel.getString(context);

    return Semantics(
      button: true,
      enabled: node.isPlayable,
      label: '$levelLabel ${node.number}, ${statusKey.getString(context)}',
      excludeSemantics: true,
      child: Material(
        color: background,
        shape: shape,
        elevation: isCurrent ? 6 : 2,
        shadowColor: const Color(0x40000000),
        child: InkWell(
          customBorder: shape,
          onTap: node.isPlayable ? onTap : null,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Padding(
              padding: const EdgeInsets.all(8),
              // Large text scales shrink to fit instead of overflowing the
              // fixed-size node.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: foreground, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      '$levelLabel ${node.number}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
