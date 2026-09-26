import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// The round map button at the foot of the level map. Opens the map
/// navigator; a pulsing dot says a reward is one board away.
class MapNavigatorButton extends StatelessWidget {
  const MapNavigatorButton({
    super.key,
    required this.onTap,
    this.showBadge = false,
  });

  static const size = 48.0;

  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final label = AppLocale.mapNavigatorLabel.getString(context);
    return Tooltip(
      message: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Pressable.small(
            onTap: onTap,
            semanticLabel: label,
            borderRadius: BorderRadius.circular(size),
            shadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
            pressedShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.map_rounded,
                color: AppColors.onSecondary,
              ),
            ),
          ),
          if (showBadge)
            const Positioned(top: -2, right: -2, child: _RewardBadge()),
        ],
      ),
    );
  }
}

/// A small gift dot that breathes, so it is noticed without nagging.
class _RewardBadge extends StatefulWidget {
  const _RewardBadge();

  @override
  State<_RewardBadge> createState() => _RewardBadgeState();
}

class _RewardBadgeState extends State<_RewardBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion keeps the dot, without the breathing.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.1).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.sun,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.surfaceContainerLowest,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.card_giftcard_rounded,
            size: 11,
            color: AppColors.onSun,
          ),
        ),
      ),
    );
  }
}

/// A speech bubble pointing down at the navigator button, shown on the
/// first visit so the button explains itself.
class MapNavigatorHint extends StatelessWidget {
  const MapNavigatorHint({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.onSurface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppLocale.mapNavigatorHint.getString(context),
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceContainerLowest,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(foregroundColor: AppColors.sun),
                  child: Text(AppLocale.gotItLabel.getString(context)),
                ),
              ],
            ),
          ),
          // The bubble's tail, over the button.
          Padding(
            padding: const EdgeInsets.only(
              right: MapNavigatorButton.size / 2 - 8,
            ),
            child: CustomPaint(
              size: const Size(16, 8),
              painter: _TailPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.onSurface);
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) => false;
}
