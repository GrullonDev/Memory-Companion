import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Loading',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.onPrimary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 96,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: AppColors.onPrimary.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryFixed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
