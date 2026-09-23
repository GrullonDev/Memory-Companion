import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/game/board/board_page.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';

/// The classic memory board, the platform's first module.
///
/// Its board modes (classic, numeric, association) stay `GameCategory`s
/// inside the module: they share one engine, one adaptive difficulty and one
/// screen, so they are variants of this game rather than separate games.
///
/// Two deliberate exceptions to the [BaseMinigame] defaults keep everything
/// already shipped working:
///  * it stays on [RoutePaths.boardSolo], where the level map, versus and old
///    deep links already point;
///  * its stats keys are the bare category ids (`'classic'`, …) that rows
///    stored before the platform existed already use.
class MemoryGameModule extends BaseMinigame {
  const MemoryGameModule();

  @override
  String get id => 'memory';

  @override
  String get titleKey => AppLocale.minigameMemoryTitle;

  @override
  String get descriptionKey => AppLocale.minigameMemoryDescription;

  @override
  IconData get icon => Icons.style_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.mint;

  @override
  String get routeName => RoutePaths.boardSolo;

  /// Reads a `GameCategory.id` from the route arguments; none plays classic.
  @override
  Widget buildGameScreen() => const BoardPage();

  @override
  String statsKeyFor(String? variantId) => GameCategories.byId(variantId).id;

  @override
  bool ownsStatsKey(String key) =>
      GameCategories.all.any((category) => category.id == key);
}
