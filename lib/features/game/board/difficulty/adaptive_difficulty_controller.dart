import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/adaptive_difficulty.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';
import 'package:memory_companion/features/game/board/difficulty/skill_repository.dart';

final skillRepositoryProvider = Provider<SkillRepository>(
  (ref) => SkillRepository(database: ref.watch(appDatabaseProvider)),
);

/// Holds each category's [SkillState] — explicit level included — keyed by
/// category id, and keeps it in the local database.
///
/// Skill is tracked per category: someone quick with pictures may still be
/// learning their sums, and one mode's boards should not leak into another's.
///
/// State stays synchronous so a board can be dealt without waiting. The
/// saved states are loaded in the background on first read (`MyApp` reads
/// this provider at startup, so that happens behind the splash); until then
/// a category plays from the engine's initial state.
class AdaptiveDifficultyController extends Notifier<Map<String, SkillState>> {
  static const _engine = AdaptiveDifficulty();

  @override
  Map<String, SkillState> build() {
    // Must outlive each board: the next round reads what the last one wrote.
    ref.keepAlive();
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    try {
      final saved = await ref.read(skillRepositoryProvider).readAll();
      // A round recorded while the read was in flight is newer than disk.
      state = {...saved, ...state};
    } catch (e, stack) {
      // No saved progress is a playable game: it starts from level 1.
      debugPrint('Error loading saved difficulty: $e\n$stack');
    }
  }

  SkillState skillFor(GameCategory category) =>
      state[category.id] ?? _engine.initialState(category);

  DifficultySettings settingsFor(GameCategory category) =>
      _engine.settingsFor(category, skillFor(category));

  void recordRound(GameCategory category, RoundPerformance round) {
    final next = _engine.update(category, skillFor(category), round);
    state = {...state, category.id: next};
    _save(category.id, next);
  }

  Future<void> _save(String categoryId, SkillState skill) async {
    try {
      await ref.read(skillRepositoryProvider).save(categoryId, skill);
    } catch (e, stack) {
      // A full disk must not break the end of a game; the session keeps
      // the level in memory either way.
      debugPrint('Error saving difficulty: $e\n$stack');
    }
  }
}

final adaptiveDifficultyProvider =
    NotifierProvider<AdaptiveDifficultyController, Map<String, SkillState>>(
      AdaptiveDifficultyController.new,
    );
