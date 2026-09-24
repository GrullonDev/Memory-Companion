import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/words/words_screen.dart';

/// Word recognition: study a list, then say which words were on it. Each
/// level passed adds two words. Trains recognition memory.
class WordsGameModule extends BaseMinigame {
  const WordsGameModule();

  @override
  String get id => 'words';

  @override
  String get titleKey => AppLocale.minigameWordsTitle;

  @override
  String get descriptionKey => AppLocale.minigameWordsDescription;

  @override
  IconData get icon => Icons.menu_book_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.violet;

  @override
  Widget buildGameScreen() => const WordsScreen();
}
