import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/app_typography.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/statistics/model/statistics_overview.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// The four headline numbers: streak, games played, record time, accuracy.
///
/// Two columns on a phone, four on a tablet. Each tile is one number big
/// enough to read at arm's length, with a single line of context under it.
class StatsKeyMetrics extends StatelessWidget {
  const StatsKeyMetrics({super.key, required this.overview});

  final StatisticsOverview overview;

  @override
  Widget build(BuildContext context) {
    final totals = overview.totals;
    final record = overview.record;
    final accuracy = totals.accuracy;
    final streakUnit = overview.currentStreak == 1
        ? AppLocale.statsDayUnit
        : AppLocale.statsDaysUnit;

    final tiles = [
      _MetricTile(
        icon: Icons.local_fire_department_rounded,
        background: AppColors.streakSoft,
        foreground: AppColors.streakStrong,
        label: AppLocale.statsCurrentStreak.getString(context),
        value: '${overview.currentStreak}',
        unit: streakUnit.getString(context),
        caption: fill(
          AppLocale.statsBestStreakCaption.getString(context),
          overview.bestStreak,
        ),
      ),
      _MetricTile(
        icon: Icons.grid_view_rounded,
        background: AppColors.skySoft,
        foreground: AppColors.skyStrong,
        label: AppLocale.statsGamesPlayed.getString(context),
        value: '${totals.games}',
        caption: fill(
          AppLocale.statsWinsCaption.getString(context),
          totals.wins,
        ),
      ),
      _MetricTile(
        icon: Icons.timer_rounded,
        background: AppColors.violetSoft,
        foreground: AppColors.violetStrong,
        label: AppLocale.statsRecordTime.getString(context),
        value: record == null ? '—' : formatDuration(record.seconds),
        caption: record == null
            ? AppLocale.statsNoRecordYet.getString(context)
            : fill(
                AppLocale.statsPairsCaption.getString(context),
                record.pairCount,
              ),
      ),
      _MetricTile(
        icon: Icons.track_changes_rounded,
        background: AppColors.mintSoft,
        foreground: AppColors.mintStrong,
        label: AppLocale.statsOverallAccuracy.getString(context),
        value: accuracy == null ? '—' : formatPercent(accuracy),
        caption: AppLocale.statsAccuracyCaption.getString(context),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= AppBreakpoints.expanded ? 4 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.gutter * (columns - 1)) /
            columns;
        // A Wrap, not a GridView: tiles size to their text, so the
        // accessible profile's larger font grows them instead of clipping.
        return Wrap(
          spacing: AppSpacing.gutter,
          runSpacing: AppSpacing.gutter,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.label,
    required this.value,
    required this.caption,
    this.unit,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String label;
  final String value;
  final String? unit;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: '$label: $value ${unit ?? ''}. $caption',
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppSize.wellSm,
                  height: AppSize.wellSm,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, size: AppSize.iconSm, color: foreground),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  value,
                  style: AppTypography.score(
                    context,
                    size: 30,
                    color: AppColors.onSurface,
                  ),
                ),
                if (unit != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      unit!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              caption,
              style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
            ),
          ],
        ),
      ),
    );
  }
}
