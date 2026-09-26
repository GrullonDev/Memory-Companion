import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/ladder/game_ladder.dart';
import 'package:memory_companion/features/ladder/ladder_reward_repository.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

final ladderRewardRepositoryProvider = Provider<LadderRewardRepository>(
  (ref) => LadderRewardRepository(
    database: ref.watch(appDatabaseProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
  ),
);

/// Rounds won per `game_stats.category_id`, live from the local database.
final winsByStatsKeyProvider = StreamProvider<Map<String, int>>((ref) {
  return ref.watch(statsRepositoryProvider).watchWinsByCategory();
});

/// Level of [game]'s ladder given the rounds won per stats key.
int minigameLevel(BaseMinigame game, Map<String, int> winsByKey) {
  var wins = 0;
  for (final entry in winsByKey.entries) {
    if (game.ownsStatsKey(entry.key)) wins += entry.value;
  }
  return wins + 1;
}

/// Every game's ladder: the memory-board modes first, in
/// `GameCategories.all` order, then the other mini-games in hub order.
///
/// Derived from the state each game already writes when a round ends, so
/// the Home and the level map redraw on their own after every win.
final gameLaddersProvider = Provider<List<GameLadder>>((ref) {
  final skills = ref.watch(adaptiveDifficultyProvider);
  final wins = ref.watch(winsByStatsKeyProvider).value ?? const {};
  return [
    for (final category in GameCategories.all)
      // A mode never played has no entry yet and starts at level 1.
      GameLadder.board(category, level: skills[category.id]?.level ?? 1),
    for (final game in MinigameRegistry.all)
      if (game.climbsByWins)
        GameLadder.minigame(game, level: minigameLevel(game, wins)),
  ];
});

/// What a mini-game's last round did on its ladder, for its result screen.
class LadderRoundNotice {
  const LadderRoundNotice({
    required this.completedLevel,
    required this.rewards,
  });

  /// The level the round completed, or null if it was not won.
  final int? completedLevel;

  /// Ladder rewards the round paid. Usually none.
  final List<LevelReward> rewards;
}

/// The last round of each mini-game, by ladder id. Replaced every time that
/// game reports a round, so a result screen never shows an old reward.
class LadderRoundNotices extends Notifier<Map<String, LadderRoundNotice>> {
  @override
  Map<String, LadderRoundNotice> build() => const {};

  void set(String ladderId, LadderRoundNotice notice) {
    state = {...state, ladderId: notice};
  }
}

final ladderRoundNoticesProvider =
    NotifierProvider<LadderRoundNotices, Map<String, LadderRoundNotice>>(
      LadderRoundNotices.new,
    );

/// Pays the ladder rewards (see [LevelRewards]) every game has earned.
///
/// Every call is idempotent — `ladder_rewards` remembers what was paid — so
/// it runs after each round and once at startup, which also delivers any
/// reward earned before the rewards existed. Never throws: nothing is lost
/// by a failed claim, the next one pays it.
class LadderService {
  LadderService(this._ref);

  final Ref _ref;

  /// After a memory-board round: [level] is the mode's new level.
  Future<List<LevelReward>> claimBoard(String categoryId, int level) {
    return _claim(categoryId, level);
  }

  /// After a mini-game round, once its `game_stats` row is written.
  Future<List<LevelReward>> claimMinigame(
    BaseMinigame game, {
    required bool won,
  }) async {
    if (!game.climbsByWins) return const [];
    final ladderId = GameLadder.minigameId(game);
    try {
      final wins = await _ref
          .read(statsRepositoryProvider)
          .watchWinsByCategory()
          .first;
      final level = minigameLevel(game, wins);
      final rewards = await _claim(ladderId, level);
      _ref
          .read(ladderRoundNoticesProvider.notifier)
          .set(
            ladderId,
            LadderRoundNotice(
              completedLevel: won ? level - 1 : null,
              rewards: rewards,
            ),
          );
      return rewards;
    } catch (e, stack) {
      debugPrint('Error claiming ${game.id} ladder rewards: $e\n$stack');
      return const [];
    }
  }

  /// Every ladder at once, from what is already saved. Run at startup.
  Future<void> claimAll({required Map<String, int> boardLevels}) async {
    for (final entry in boardLevels.entries) {
      await _claim(entry.key, entry.value);
    }
    try {
      final wins = await _ref
          .read(statsRepositoryProvider)
          .watchWinsByCategory()
          .first;
      for (final game in MinigameRegistry.all.where((g) => g.climbsByWins)) {
        await _claim(GameLadder.minigameId(game), minigameLevel(game, wins));
      }
    } catch (e, stack) {
      debugPrint('Error claiming mini-game ladder rewards: $e\n$stack');
    }
  }

  Future<List<LevelReward>> _claim(String ladderId, int level) async {
    try {
      // Straight from the repository: it must not depend on some screen
      // keeping `localPlayerProvider` alive.
      final player = await _ref
          .read(playerRepositoryProvider)
          .ensureLocalProfile();
      return await _ref
          .read(ladderRewardRepositoryProvider)
          .claim(
            ladderId: ladderId,
            level: level,
            playerLocalId: player.localId,
          );
    } catch (e, stack) {
      debugPrint('Error claiming $ladderId ladder rewards: $e\n$stack');
      return const [];
    }
  }
}

final ladderServiceProvider = Provider<LadderService>(LadderService.new);
