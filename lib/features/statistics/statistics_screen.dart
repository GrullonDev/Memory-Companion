import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/core/widgets/section_header.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';
import 'package:memory_companion/features/statistics/model/statistics_overview.dart';
import 'package:memory_companion/features/statistics/widget/game_history_tile.dart';
import 'package:memory_companion/features/statistics/widget/stats_evolution_chart.dart';
import 'package:memory_companion/features/statistics/widget/stats_key_metrics.dart';
import 'package:memory_companion/features/statistics/widget/stats_trend_card.dart';

/// The player's progress: headline numbers, this week's trend, the weekly
/// evolution and the game-by-game history.
///
/// Everything comes from the local database. The overview is a handful of
/// aggregate rows however many games exist, and the history is a lazy
/// sliver list fed a page at a time, so the screen costs the same with ten
/// games as with a thousand.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(statisticsOverviewProvider);
    final isEmpty = overview.value?.isEmpty ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _Header()),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
                vertical: AppSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: AsyncValueView(
                  value: overview,
                  onRetry: () => ref.invalidate(statisticsOverviewProvider),
                  data: (context, StatisticsOverview data) => data.isEmpty
                      ? const _EmptyState()
                      : _Overview(overview: data),
                ),
              ),
            ),
            if (!isEmpty) ..._historySlivers(context, ref),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.lg,
                AppSpacing.screenMargin,
                AppSpacing.xxl,
              ),
              sliver: SliverToBoxAdapter(child: _PrivacyNote()),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _historySlivers(BuildContext context, WidgetRef ref) {
    final history = ref.watch(gameHistoryProvider).value;
    final games = history?.games ?? const [];
    const margin = EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin);

    return [
      SliverPadding(
        padding: margin.copyWith(top: AppSpacing.sm),
        sliver: SliverToBoxAdapter(
          child: SectionHeader(
            title: AppLocale.statsHistoryTitle.getString(context),
          ),
        ),
      ),
      SliverPadding(
        padding: margin,
        sliver: SliverList.separated(
          itemCount: games.length,
          itemBuilder: (context, i) => GameHistoryTile(game: games[i]),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        ),
      ),
      if (history?.hasMore ?? false)
        SliverPadding(
          padding: margin.copyWith(top: AppSpacing.md),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSize.touchComfortable),
                ),
                onPressed: () =>
                    ref.read(gameHistoryProvider.notifier).loadMore(),
                child: Text(AppLocale.statsLoadMore.getString(context)),
              ),
            ),
          ),
        ),
    ];
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              AppLocale.statisticsTitle.getString(context),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.overview});

  final StatisticsOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsKeyMetrics(overview: overview),
        const SizedBox(height: AppSpacing.xl),
        StatsTrendCard(trend: overview.trend),
        const SizedBox(height: AppSpacing.xl),
        StatsEvolutionChart(weeks: overview.weeks),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.huge),
      child: Column(
        children: [
          const Icon(
            Icons.insights_rounded,
            size: 64,
            color: AppColors.skyStrong,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            AppLocale.statsEmptyTitle.getString(context),
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocale.statsEmptySubtitle.getString(context),
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: AppSize.iconXs,
          color: AppColors.outline,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            AppLocale.statsPrivacyNote.getString(context),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.outline),
          ),
        ),
      ],
    );
  }
}
