import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/sudoku_screen.dart';

/// Sudoku that grows with the player: 4 × 4, then 6 × 6, then the classic
/// 9 × 9 with fewer clues every level. Trains logic and working memory.
class SudokuGameModule extends BaseMinigame {
  const SudokuGameModule();

  @override
  String get id => 'sudoku';

  @override
  String get titleKey => AppLocale.minigameSudokuTitle;

  @override
  String get descriptionKey => AppLocale.minigameSudokuDescription;

  @override
  IconData get icon => Icons.grid_3x3_rounded;

  @override
  MinigamePalette get palette => MinigamePalette.sky;

  @override
  Widget buildGameScreen() => const SudokuScreen();
}
