import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';

/// The category the level map shows and opens. The board is pushed with its
/// id, so the path and the board it leads to can never disagree.
const GameCategory levelMapCategory = GameCategories.classic;

/// The level map's nodes, derived from the player's real progress.
///
/// Watches the same state `BoardController` writes when a round ends (and
/// `SkillRepository` keeps in Drift), so there is nothing to invalidate: a
/// won board raises `SkillState.level`, this provider recomputes, and the
/// map — still mounted under the board route — is already redrawn when the
/// player returns to it. Saved progress restored from the database at
/// startup arrives the same way.
final levelMapProvider = Provider<List<LevelNode>>((ref) {
  final currentLevel = ref.watch(
    // A category never played has no entry yet and starts at level 1.
    adaptiveDifficultyProvider.select(
      (skills) => skills[levelMapCategory.id]?.level ?? 1,
    ),
  );
  return LevelNode.pathAround(currentLevel);
});
