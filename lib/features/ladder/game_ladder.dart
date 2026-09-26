import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';

/// Where the player stands on one game's level ladder.
///
/// Every game keeps its own ladder: being on level 7 of the classic board
/// says nothing about the crossword. Two kinds exist, with one shape:
///  * each memory-board mode (`GameCategory`) climbs with the adaptive
///    difficulty, one level per board won (`SkillState.level`);
///  * every other mini-game climbs one level per round won, counted from
///    `game_stats` (see [BaseMinigame.climbsByWins]).
///
/// A read-only view: the level, and the ladder reward it is heading to.
class GameLadder {
  const GameLadder({
    required this.id,
    required this.nameKey,
    required this.level,
  });

  GameLadder.board(GameCategory category, {required int level})
    : this(id: boardId(category), nameKey: category.nameKey, level: level);

  GameLadder.minigame(BaseMinigame game, {required int level})
    : this(id: minigameId(game), nameKey: game.titleKey, level: level);

  /// Ladder id of a memory-board mode. The bare category id, like its
  /// `category_levels` row.
  static String boardId(GameCategory category) => category.id;

  /// Ladder id of a mini-game. Namespaced so it can never collide with a
  /// board mode.
  static String minigameId(BaseMinigame game) => 'game:${game.id}';

  final String id;

  /// `AppLocale` key of the game's name.
  final String nameKey;

  /// The level to play next: 1 plus every level completed.
  final int level;

  int get completedLevels => level - 1;

  /// The next ladder reward. Always ahead of the player.
  LevelReward get nextReward => LevelRewards.nextAfter(completedLevels);

  /// Levels still to complete before [nextReward]. 1 to [LevelRewards.every].
  int get levelsUntilReward => LevelRewards.levelsUntilNext(completedLevels);

  /// Progress towards [nextReward], 0.0 to 1.0.
  double get rewardProgress =>
      LevelRewards.progressTowardsNext(completedLevels);

  @override
  bool operator ==(Object other) =>
      other is GameLadder &&
      other.id == id &&
      other.nameKey == nameKey &&
      other.level == level;

  @override
  int get hashCode => Object.hash(id, nameKey, level);

  @override
  String toString() => 'GameLadder($id, level: $level)';
}
