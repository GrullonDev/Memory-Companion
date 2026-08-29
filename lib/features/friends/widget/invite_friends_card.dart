import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

class InviteFriendsCard extends StatelessWidget {
  const InviteFriendsCard({
    super.key,
    this.onShare,
    this.onCopyCode,
    this.onInvite,
  });

  final VoidCallback? onShare;
  final VoidCallback? onCopyCode;
  final VoidCallback? onInvite;

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
          AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(
              painter: const _DashedBoxPainter(),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(
                      Icons.qr_code_2_rounded,
                      size: 120,
                      color: AppColors.secondary,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _CornerButton(
                      icon: Icons.share_rounded,
                      onTap: onShare,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _CornerButton(
                      icon: Icons.copy_rounded,
                      onTap: onCopyCode,
                    ),
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
            child: Material(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onInvite,
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
                        Icons.play_arrow_rounded,
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
  const _CornerButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Dashed rounded-rectangle border standing in for a photographed lobby
/// scene behind the QR code — no such artwork asset exists in the project.
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
