import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/statistics/model/category_title.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// One finished game in the history: mode, date, time, accuracy, errors,
/// and where and with whom it was played when that was recorded.
///
/// Memory-board rows name the board mode and size; rows from other
/// mini-games name the game, since their `pair_count` is not pairs.
class GameHistoryTile extends StatelessWidget {
  const GameHistoryTile({super.key, required this.game, this.placeLabel});

  final GameStats game;

  /// The name of the place it was played at, when it has one.
  final String? placeLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).languageCode;
    final isBoard = isBoardCategory(game.categoryId);
    final name = categoryTitleKey(game.categoryId).getString(context);
    final title = isBoard
        ? '$name · '
              '${fill(AppLocale.statsPairsCaption.getString(context), game.pairCount)}'
        : name;
    final people = [
      for (final player in game.nearby ?? const []) player.name ?? player.code,
    ];
    final contextLine = [?placeLabel, if (people.isNotEmpty) people.join(', ')];
    final (resultIcon, resultColor, resultKey) = game.won
        ? (
            Icons.check_circle_rounded,
            AppColors.mintStrong,
            AppLocale.statsWonLabel,
          )
        : (
            Icons.timer_off_rounded,
            AppColors.outline,
            isBoard
                ? AppLocale.statsLostLabel
                : AppLocale.statsNotCompletedLabel,
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
                Text(title, style: textTheme.titleSmall),
                Text(
                  '${DateFormat.MMMd(locale).add_Hm().format(game.date)} · '
                  '${resultKey.getString(context)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (contextLine.isNotEmpty)
                  Text(
                    contextLine.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.outline,
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
