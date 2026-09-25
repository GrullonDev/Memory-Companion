import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_screen.dart';

/// Word-wheel crossword: spell words from a handful of letters to fill a
/// small crossword. Trains vocabulary retrieval.
///
/// Stats keys carry the puzzle language (`'crossword:es'`), because the
/// number of puzzles won in a language is also the player's level there.
class CrosswordGameModule extends BaseMinigame {
  const CrosswordGameModule();

  @override
  String get id => 'crossword';

  @override
  String get titleKey => AppLocale.minigameCrosswordTitle;

  @override
  String get descriptionKey => AppLocale.minigameCrosswordDescription;

  @override
  IconData get icon => Icons.grid_on_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.streak;

  @override
  Widget buildGameScreen() => const CrosswordScreen();
}
