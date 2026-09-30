import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/slide/slide_screen.dart';

/// The classic sliding puzzle: put the numbered tiles back in order. Boards
/// grow from 3 × 3 to 5 × 5 and get more scrambled every level. Trains
/// planning.
class SlideGameModule extends BaseMinigame {
  const SlideGameModule();

  @override
  String get id => 'slide';

  @override
  String get titleKey => AppLocale.minigameSlideTitle;

  @override
  String get descriptionKey => AppLocale.minigameSlideDescription;

  @override
  IconData get icon => Icons.view_module_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.sky;

  @override
  Widget buildGameScreen() => const SlideScreen();
}
