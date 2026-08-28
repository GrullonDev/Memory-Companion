import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

class NextLevelCard extends StatelessWidget {
  const NextLevelCard({
    super.key,
    required this.currentXp,
    required this.targetXp,
  });

  final int currentXp;
  final int targetXp;

  @override
  Widget build(BuildContext context) {
    final progress = targetXp == 0
        ? 0.0
        : (currentXp / targetXp).clamp(0.0, 1.0);
    final numberFormat = NumberFormat.decimalPattern();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocale.nextLevelLabel.getString(context),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${numberFormat.format(currentXp)} / ${numberFormat.format(targetXp)} XP',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.surfaceContainerHigh,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.primaryFixedDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
