import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Stylized forest backdrop for the level map: a soft green/teal gradient
/// with a scatter of low-opacity tree glyphs standing in for painted art.
class ForestBackdrop extends StatelessWidget {
  const ForestBackdrop({super.key});

  static const _trees = [
    (top: 40.0, left: 24.0, size: 34.0),
    (top: 120.0, left: 260.0, size: 26.0),
    (top: 30.0, left: 180.0, size: 20.0),
    (top: 220.0, left: 40.0, size: 30.0),
    (top: 300.0, left: 240.0, size: 22.0),
    (top: 400.0, left: 90.0, size: 28.0),
    (top: 480.0, left: 220.0, size: 34.0),
    (top: 560.0, left: 30.0, size: 24.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.secondaryFixed, AppColors.mintGreen],
          ),
        ),
        child: Stack(
          children: [
            for (final tree in _trees)
              Positioned(
                top: tree.top,
                left: tree.left,
                child: Icon(
                  Icons.park_rounded,
                  size: tree.size,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
