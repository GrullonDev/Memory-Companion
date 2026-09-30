import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/colors/colors_screen.dart';

/// The Stroop test as a game: a colour word painted in another colour, and
/// the player taps the ink, not the word. Trains attention and inhibition.
class ColorsGameModule extends BaseMinigame {
  const ColorsGameModule();

  @override
  String get id => 'colors';

  @override
  String get titleKey => AppLocale.minigameColorsTitle;

  @override
  String get descriptionKey => AppLocale.minigameColorsDescription;

  @override
  IconData get icon => Icons.palette_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.streak;

  @override
  Widget buildGameScreen() => const ColorsScreen();
}
