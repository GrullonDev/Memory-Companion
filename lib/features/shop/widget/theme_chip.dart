import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

class ThemeChip extends StatelessWidget {
  const ThemeChip({super.key, required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.secondaryFixed,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.onSurface, width: 2),
          ),
          child: Icon(icon, size: 30, color: AppColors.onSurface),
        ),
      ),
    );
  }
}
