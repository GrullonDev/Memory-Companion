import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/game_context/service/game_context_capturer.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';
import 'package:memory_companion/features/statistics/model/game_stats.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';

/// The single door through which every mini-game writes to `game_stats`.
///
/// Local only: it never touches the network or the sync queue, so it works
/// offline and needs no account. When the player turned on the automatic
/// context, the row also gets where and with whom the game was played.
class MinigameResultReporter {
  MinigameResultReporter({
    required StatsRepository repository,
    required DateTime Function() clock,
    GameContextCapturer? context,
  }) : _repository = repository,
       _clock = clock,
       _context = context;

  final StatsRepository _repository;
  final DateTime Function() _clock;
  final GameContextCapturer? _context;

  /// Stores [result] under [game]'s stats key.
  ///
  /// Never throws: a full disk must not break the end of a round.
  Future<void> report(BaseMinigame game, MinigameResult result) async {
    // Read before the context: the game ended now, not after the scan.
    final date = _clock();
    try {
      final context = await _context?.capture() ?? GameContext.none;
      await _repository.record(
        GameStats(
          date: date,
          categoryId: game.statsKeyFor(result.variantId),
          pairCount: result.itemCount,
          matchedPairs: result.itemsSolved,
          moves: result.attempts,
          memoryErrors: result.errors,
          hintsUsed: result.hintsUsed,
          timeSeconds: result.secondsElapsed,
          timeLimitSeconds: result.timeLimitSeconds,
          timed: result.timed,
          won: result.won,
          score: result.score,
          placeId: context.placeId,
          nearby: context.nearby,
        ),
      );
    } catch (e, stack) {
      debugPrint('Error saving ${game.id} stats: $e\n$stack');
    }
  }
}

/// Read it synchronously before any `await` in a controller: once the
/// player leaves the screen, an auto-disposed provider's `ref` stops working.
final minigameResultReporterProvider = Provider<MinigameResultReporter>((ref) {
  return MinigameResultReporter(
    repository: ref.watch(statsRepositoryProvider),
    clock: ref.watch(statsClockProvider),
    context: ref.watch(gameContextCapturerProvider),
  );
});
