import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';

/// The one progress indicator in the app: XP toward the next level, a daily
/// goal, a level's completion.
///
/// The track is thick and fully rounded so the fill is legible at a glance
/// from arm's length, and it animates to its new value rather than jumping,
/// which is what makes earning XP feel like a reward instead of a number
/// changing. The percentage is exposed to screen readers via [Semantics].
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.sunDeep,
    this.trackColor = AppColors.surfaceContainerHigh,
    this.height = AppSize.progressBarHeight,
    this.animate = true,
    this.semanticLabel,
  });

  /// 0.0 – 1.0. Values outside the range are clamped.
  final double value;
  final Color color;
  final Color trackColor;
  final double height;
  final bool animate;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();

    return Semantics(
      label: semanticLabel,
      value: '$percent%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Container(
          height: height,
          color: trackColor,
          child: Align(
            alignment: Alignment.centerLeft,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final target = constraints.maxWidth * clamped;
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: target),
                  duration: animate ? AppMotion.slow : Duration.zero,
                  curve: AppMotion.emphasized,
                  builder: (context, width, _) {
                    if (width <= 0) return const SizedBox.shrink();
                    return Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(height),
                      ),
                      // A soft highlight along the top half reads as a
                      // moulded, plastic surface rather than a flat bar.
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: height * 0.36,
                          margin: EdgeInsets.symmetric(
                            horizontal: height * 0.28,
                            vertical: height * 0.16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(height),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
