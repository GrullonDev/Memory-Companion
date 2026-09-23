import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// One finished game in the history: mode, date, time, accuracy, errors.
class GameHistoryTile extends StatelessWidget {
  const GameHistoryTile({super.key, required this.game});

  final GameStats game;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final category = GameCategories.byId(game.categoryId);
    final (resultIcon, resultColor, resultKey) = game.won
        ? (
            Icons.check_circle_rounded,
            AppColors.mintStrong,
            AppLocale.statsWonLabel,
          )
        : (
            Icons.timer_off_rounded,
            AppColors.outline,
            AppLocale.statsLostLabel,
          );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(resultIcon, color: resultColor, size: AppSize.iconLg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category.nameKey.getString(context)} · '
                  '${fill(AppLocale.statsPairsCaption.getString(context), game.pairCount)}',
                  style: textTheme.titleSmall,
                ),
                Text(
                  '${DateFormat.MMMd(locale).add_Hm().format(game.date)} · '
                  '${resultKey.getString(context)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatDuration(game.timeSeconds),
                style: textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${formatPercent(game.accuracy)} · '
                '${fill(AppLocale.statsErrorsCount.getString(context), game.memoryErrors)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
