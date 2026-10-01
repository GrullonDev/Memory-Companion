import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/pattern/pattern_screen.dart';

/// Some cells of a grid light up for a moment; tap where they were. Grids
/// grow and patterns get busier level after level. Trains spatial memory.
class PatternGameModule extends BaseMinigame {
  const PatternGameModule();

  @override
  String get id => 'pattern';

  @override
  String get titleKey => AppLocale.minigamePatternTitle;

  @override
  String get descriptionKey => AppLocale.minigamePatternDescription;

  @override
  IconData get icon => Icons.apps_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.mint;

  @override
  Widget buildGameScreen() => const PatternScreen();
}
