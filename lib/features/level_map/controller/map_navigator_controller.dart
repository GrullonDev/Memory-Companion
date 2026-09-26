import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty_controller.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/level_map/controller/level_map_controller.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';

/// What the level map's navigator summarises: where the player is on the
/// map and how close the next ladder reward is.
///
/// Pure arithmetic over the level, like [LevelRewards], so it needs no
/// storage and is always in step with the path.
class MapProgress {
  const MapProgress({required this.currentLevel});

  final int currentLevel;

  int get levelsCleared => currentLevel - 1;

  LevelReward get nextReward => LevelRewards.nextAfter(levelsCleared);

  int get levelsToReward => LevelRewards.levelsUntilNext(levelsCleared);

  double get rewardProgress => LevelRewards.progressTowardsNext(levelsCleared);

  /// One more board won pays the next reward: worth a badge on the button.
  bool get rewardWithinReach => levelsToReward == 1;

  @override
  bool operator ==(Object other) =>
      other is MapProgress && other.currentLevel == currentLevel;

  @override
  int get hashCode => currentLevel.hashCode;
}

final mapProgressProvider = Provider<MapProgress>((ref) {
  final level = ref.watch(
    adaptiveDifficultyProvider.select(
      (skills) => skills[levelMapCategory.id]?.level ?? 1,
    ),
  );
  return MapProgress(currentLevel: level < 1 ? 1 : level);
});

/// Whether the navigator should explain itself: only once, and only after
/// the saved preferences arrived, so it never flashes for someone who has
/// already seen it.
final mapNavigatorHintProvider = Provider<bool>((ref) {
  final prefs = ref.watch(displayPreferencesControllerProvider);
  return prefs.hasValue && !prefs.requireValue.mapNavigatorHintSeen;
});

/// Remembers that the navigator hint was shown. Best effort: at worst the
/// hint appears once more.
Future<void> dismissMapNavigatorHint(WidgetRef ref) async {
  try {
    await ref
        .read(displayPreferencesControllerProvider.notifier)
        .markMapNavigatorHintSeen();
  } on Exception {
    // Ignored on purpose.
  }
}
