import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_screen.dart';

/// Digit span: remember a number that grows one digit per correct answer,
/// in order or backwards. Trains working memory.
///
/// Stats keys: `'digits'` forward, `'digits:reverse'` backwards.
class DigitsGameModule extends BaseMinigame {
  const DigitsGameModule();

  @override
  String get id => 'digits';

  @override
  String get titleKey => AppLocale.minigameDigitsTitle;

  @override
  String get descriptionKey => AppLocale.minigameDigitsDescription;

  @override
  IconData get icon => Icons.pin_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.sky;

  @override
  Widget buildGameScreen() => const DigitsScreen();
}
