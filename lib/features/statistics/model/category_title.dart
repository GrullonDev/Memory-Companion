import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';
import 'package:memory_companion/features/minigames/modules/memory/memory_game_module.dart';

/// Whether a `game_stats.category_id` belongs to the memory board.
///
/// Rows from before the platform, or from a removed game, read as board
/// games — the only kind there used to be.
bool isBoardCategory(String categoryId) {
  final minigame = MinigameRegistry.ownerOfStatsKey(categoryId);
  return minigame == null || minigame is MemoryGameModule;
}

/// The `AppLocale` key that names a `game_stats.category_id`: the board
/// category for memory-board rows, the game's title for the others.
String categoryTitleKey(String categoryId) {
  final minigame = MinigameRegistry.ownerOfStatsKey(categoryId);
  if (minigame == null || minigame is MemoryGameModule) {
    return GameCategories.byId(categoryId).nameKey;
  }
  return minigame.titleKey;
}
