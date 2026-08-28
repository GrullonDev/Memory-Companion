import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/profile/model/profile_match.dart';

class MatchHistoryTile extends StatelessWidget {
  const MatchHistoryTile({super.key, required this.match});

  final ProfileMatch match;

  @override
  Widget build(BuildContext context) {
    final isWin = match.result == MatchResult.win;
    final accent = isWin ? AppColors.mintGreen : AppColors.error;
    final onAccent = isWin ? AppColors.onMintGreen : AppColors.onError;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withValues(alpha: 0.18),
            child: Icon(
              isWin ? Icons.emoji_events_rounded : Icons.close_rounded,
              color: isWin ? onAccent : accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppLocale.scoreLabel.getString(context)}: ${match.score} · '
                  '${AppLocale.movesLabel.getString(context)}: ${match.moves}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            match.timeAgo,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}
