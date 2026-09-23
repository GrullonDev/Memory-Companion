import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/statistics/model/statistics_overview.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// This week against the last: a one-line verdict, then speed, accuracy and
/// memory errors, each with an arrow, a word and a number.
///
/// Wording is always framed from the player's side ("12 % faster", "fewer
/// errors") and a worse week is phrased as encouragement, never as a
/// diagnosis — an older player reading this with family should come away
/// motivated, not worried.
class StatsTrendCard extends StatelessWidget {
  const StatsTrendCard({super.key, required this.trend});

  final StatsTrend trend;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final overall = trend.overall;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocale.statsTrendTitle.getString(context),
            style: textTheme.titleMedium,
          ),
          Text(
            AppLocale.statsTrendSubtitle.getString(context),
            style: textTheme.bodySmall?.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.md),
          _Verdict(direction: overall),
          if (overall != TrendDirection.notEnoughData) ...[
            const SizedBox(height: AppSpacing.md),
            _MetricRow(
              icon: Icons.speed_rounded,
              label: AppLocale.statsSpeedLabel.getString(context),
              trend: trend.speed,
              describe: (change) => change >= 0
                  ? AppLocale.statsChangeFaster
                  : AppLocale.statsChangeSlower,
            ),
            const Divider(height: AppSpacing.lg),
            _MetricRow(
              icon: Icons.track_changes_rounded,
              label: AppLocale.statsAccuracyLabel.getString(context),
              trend: trend.accuracy,
              describe: (change) => change >= 0
                  ? AppLocale.statsChangePointsUp
                  : AppLocale.statsChangePointsDown,
            ),
            const Divider(height: AppSpacing.lg),
            _MetricRow(
              icon: Icons.psychology_rounded,
              label: AppLocale.statsErrorsLabel.getString(context),
              trend: trend.errors,
              describe: (change) => change >= 0
                  ? AppLocale.statsChangeFewer
                  : AppLocale.statsChangeMore,
            ),
          ],
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.direction});

  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground, key) = switch (direction) {
      TrendDirection.improving => (
        Icons.trending_up_rounded,
        AppColors.mintSoft,
        AppColors.mintStrong,
        AppLocale.statsTrendImproving,
      ),
      TrendDirection.steady => (
        Icons.trending_flat_rounded,
        AppColors.skySoft,
        AppColors.skyStrong,
        AppLocale.statsTrendSteady,
      ),
      // Encouragement, not alarm: warm, never the error red.
      TrendDirection.declining => (
        Icons.favorite_rounded,
        AppColors.sunSoft,
        AppColors.sunStrong,
        AppLocale.statsTrendDeclining,
      ),
      TrendDirection.notEnoughData => (
        Icons.insights_rounded,
        AppColors.surfaceContainerLow,
        AppColors.onSurfaceVariant,
        AppLocale.statsTrendNotEnough,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: AppSize.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              key.getString(context),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.trend,
    required this.describe,
  });

  final IconData icon;
  final String label;
  final MetricTrend trend;

  /// Picks the template for a change; positive means better. Every change
  /// is a fraction, so the number shown is always `× 100`: percent for
  /// speed and errors, percentage points for accuracy.
  final String Function(double change) describe;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Not arrows: an up arrow beside "20 % fewer errors" reads backwards.
    // The icon says good or not-yet; the text says which way.
    final (arrow, color) = switch (trend.direction) {
      TrendDirection.improving => (
        Icons.check_circle_rounded,
        AppColors.mintStrong,
      ),
      TrendDirection.declining => (
        Icons.hourglass_bottom_rounded,
        AppColors.sunStrong,
      ),
      _ => (Icons.remove_rounded, AppColors.outline),
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: ${_describe(context)}',
      child: Row(
        children: [
          Icon(icon, size: AppSize.iconSm, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
          Icon(arrow, size: AppSize.iconSm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _describe(context),
            style: textTheme.labelLarge?.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }

  String _describe(BuildContext context) {
    final change = trend.change;
    return switch (trend.direction) {
      TrendDirection.notEnoughData => AppLocale.statsChangeNoData.getString(
        context,
      ),
      TrendDirection.steady => AppLocale.statsChangeSteady.getString(context),
      // Errors rose from zero: no base for a percentage.
      TrendDirection.improving when change == null =>
        AppLocale.statsChangeBetter.getString(context),
      TrendDirection.declining when change == null =>
        AppLocale.statsChangeWorse.getString(context),
      _ => fill(
        describe(change!).getString(context),
        (change.abs() * 100).round(),
      ),
    };
  }
}
