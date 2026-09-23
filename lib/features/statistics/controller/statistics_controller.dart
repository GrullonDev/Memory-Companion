import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/model/statistics_overview.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';
import 'package:memory_companion/features/statistics/service/stats_analytics.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(database: ref.watch(appDatabaseProvider));
});

final statsAnalyticsProvider = Provider<StatsAnalytics>(
  (ref) => const StatsAnalytics(),
);

/// "Now" for the statistics. Overridden in tests to pin today's date.
final statsClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Streaks, totals, weekly evolution and trend — live from the local
/// database. Re-emits after every finished game; disposed when no screen is
/// showing it, so "today" is re-read on the next visit.
final statisticsOverviewProvider =
    StreamProvider.autoDispose<StatisticsOverview>((ref) {
      final repository = ref.watch(statsRepositoryProvider);
      final analytics = ref.watch(statsAnalyticsProvider);
      final today = ref.watch(statsClockProvider)();

      return repository
          .watchSnapshot(sinceDay: analytics.windowStartDay(today))
          .map((snapshot) => analytics.analyze(snapshot, today));
    });

/// The game-by-game history, loaded a page at a time.
class GameHistory {
  const GameHistory({required this.games, required this.hasMore});

  final List<GameStats> games;
  final bool hasMore;
}

class GameHistoryController extends AsyncNotifier<GameHistory> {
  static const pageSize = 20;

  bool _loadingMore = false;

  @override
  Future<GameHistory> build() async {
    // Starts over from the newest page whenever a game is stored, so the
    // list never disagrees with the totals shown above it.
    ref.watch(statisticsOverviewProvider);
    return _page(const []);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      state = AsyncData(await _page(current.games));
    } finally {
      _loadingMore = false;
    }
  }

  Future<GameHistory> _page(List<GameStats> loaded) async {
    final page = await ref
        .read(statsRepositoryProvider)
        .recentGames(
          limit: pageSize,
          beforeId: loaded.isEmpty ? null : loaded.last.id,
        );
    return GameHistory(
      games: [...loaded, ...page],
      hasMore: page.length == pageSize,
    );
  }
}

final gameHistoryProvider =
    AsyncNotifierProvider.autoDispose<GameHistoryController, GameHistory>(
      GameHistoryController.new,
    );
