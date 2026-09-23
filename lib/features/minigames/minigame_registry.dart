import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/memory/memory_game_module.dart';

/// Every mini-game the platform offers, in hub order.
///
/// Registering a new game is one line in [all]: the hub lists it, the router
/// serves its [BaseMinigame.routeName], and its results land in `game_stats`
/// through `MinigameResultReporter`.
abstract final class MinigameRegistry {
  static const List<BaseMinigame> all = [
    MemoryGameModule(),
    // SequenceGameModule(),  ← a new game is one line here.
  ];

  static BaseMinigame? byId(String id) =>
      all.where((game) => game.id == id).firstOrNull;

  static BaseMinigame? byRoute(String? routeName) =>
      all.where((game) => game.routeName == routeName).firstOrNull;

  /// Which game wrote a `game_stats.category_id`, for labelling history.
  static BaseMinigame? ownerOfStatsKey(String key) =>
      all.where((game) => game.ownsStatsKey(key)).firstOrNull;

  /// The route for a registered game, or null so `RouteSwitch` falls through
  /// to its own table. [settings] are kept so the screen can read its
  /// arguments.
  static Route<dynamic>? routeFor(RouteSettings settings) {
    final game = byRoute(settings.name);
    if (game == null) return null;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => game.buildGameScreen(),
    );
  }
}

/// The games the hub shows. Overridable in tests; later the place to hide
/// games behind a plan or a feature flag.
final minigamesProvider = Provider<List<BaseMinigame>>(
  (ref) => MinigameRegistry.all,
);
