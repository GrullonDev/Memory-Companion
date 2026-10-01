import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/math/math_screen.dart';

/// Quick arithmetic against the clock: sums first, then subtraction,
/// products and divisions as the levels go up. Trains processing speed.
class MathGameModule extends BaseMinigame {
  const MathGameModule();

  @override
  String get id => 'math';

  @override
  String get titleKey => AppLocale.minigameMathTitle;

  @override
  String get descriptionKey => AppLocale.minigameMathDescription;

  @override
  IconData get icon => Icons.calculate_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.sun;

  @override
  Widget buildGameScreen() => const MathScreen();
}
