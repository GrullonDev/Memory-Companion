import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

class BoardBottomBar extends StatelessWidget {
  const BoardBottomBar({
    super.key,
    required this.isPaused,
    required this.onTogglePause,
    required this.onHint,
  });

  final bool isPaused;
  final VoidCallback onTogglePause;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _RoundButton(
          icon: isPaused ? Icons.play_arrow : Icons.pause,
          background: AppColors.surfaceContainerLowest,
          foreground: AppColors.onSurface,
          onTap: onTogglePause,
        ),
        _RoundButton(
          icon: Icons.lightbulb,
          background: AppColors.primaryFixed,
          foreground: AppColors.onPrimaryFixed,
          onTap: onHint,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: foreground, size: 26),
        ),
      ),
    );
  }
}
