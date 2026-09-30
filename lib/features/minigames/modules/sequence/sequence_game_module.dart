import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/sequence/sequence_screen.dart';

/// Pads light up one after another; tap them back in the same order. The
/// sequence grows with every one repeated. Trains visuospatial memory.
class SequenceGameModule extends BaseMinigame {
  const SequenceGameModule();

  @override
  String get id => 'sequence';

  @override
  String get titleKey => AppLocale.minigameSequenceTitle;

  @override
  String get descriptionKey => AppLocale.minigameSequenceDescription;

  @override
  IconData get icon => Icons.touch_app_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.violet;

  @override
  Widget buildGameScreen() => const SequenceScreen();
}
