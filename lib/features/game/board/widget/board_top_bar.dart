import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

class BoardTopBar extends StatelessWidget {
  const BoardTopBar({super.key, required this.progress, required this.moves});

  final double progress;
  final int moves;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.timer_outlined, color: AppColors.primary, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.primaryFixedDim,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          AppLocale.appTitle.getString(context),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${AppLocale.movesLabel.getString(context)}: ',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: moves.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
