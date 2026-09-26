import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// The player's own friend code, with ways to share it.
class InviteFriendsCard extends StatelessWidget {
  const InviteFriendsCard({
    super.key,
    required this.friendCode,
    this.onShare,
    this.onCopyCode,
  });

  final String friendCode;
  final VoidCallback? onShare;
  final VoidCallback? onCopyCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: const Border(
          top: BorderSide(color: AppColors.secondaryContainer, width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocale.inviteFriendsTitle.getString(context),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          CustomPaint(
            painter: const _DashedBoxPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 20),
              child: Row(
                children: [
                  _CornerButton(
                    icon: Icons.share_rounded,
                    tooltip: AppLocale.inviteLinkLabel.getString(context),
                    onTap: onShare,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          AppLocale.yourFriendCodeLabel.getString(context),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SelectableText(
                            friendCode,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CornerButton(
                    icon: Icons.copy_rounded,
                    tooltip: AppLocale.codeCopiedMessage.getString(context),
                    onTap: onCopyCode,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocale.inviteFriendsSubtitle.getString(context),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Pressable(
              onTap: onShare,
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.tertiary, width: 4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.share_rounded,
                        color: AppColors.onPrimaryFixed,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          AppLocale.inviteLinkLabel.getString(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.onPrimaryFixed,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerButton extends StatelessWidget {
  const _CornerButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable.small(
        onTap: onTap,
        child: Material(
          color: AppColors.surfaceContainerLowest,
          shape: const CircleBorder(),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded-rectangle border framing the friend code.
class _DashedBoxPainter extends CustomPainter {
  const _DashedBoxPainter();

  static const double _dashLength = 8;
  static const double _gapLength = 6;
  static const double _radius = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(_radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = AppColors.outlineVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + _dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + _gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBoxPainter oldDelegate) => false;
}
