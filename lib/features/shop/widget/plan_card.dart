import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/shop/model/plan_feature.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.icon,
    required this.title,
    required this.features,
    required this.footer,
    this.badge,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final List<PlanFeature> features;
  final Widget footer;
  final Widget? badge;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: highlighted ? AppColors.primaryFixedDim : AppColors.outlineVariant,
          width: highlighted ? 3 : 1,
        ),
        boxShadow: highlighted
            ? const [
                BoxShadow(
                  color: Color(0x40E6B400),
                  offset: Offset(0, 8),
                  blurRadius: 24,
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: highlighted ? AppColors.primaryFixedDim : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ?badge,
            ],
          ),
          const SizedBox(height: 16),
          for (final feature in features) ...[
            _FeatureRow(feature: feature, highlighted: highlighted),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          footer,
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature, required this.highlighted});

  final PlanFeature feature;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final iconData = feature.icon ??
        (feature.included ? Icons.check_rounded : Icons.close_rounded);
    final color = !feature.included
        ? AppColors.outline
        : highlighted
            ? AppColors.onPrimaryFixedVariant
            : AppColors.mintGreen;
    return Row(
      children: [
        Icon(iconData, size: 20, color: color),
        const SizedBox(width: 10),
        Text(
          feature.label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: feature.included ? AppColors.onSurface : AppColors.outline,
          ),
        ),
      ],
    );
  }
}
