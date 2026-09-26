import 'package:flutter/material.dart';

import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_game_module.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_game_module.dart';
import 'package:memory_companion/features/minigames/modules/memory/memory_game_module.dart';
import 'package:memory_companion/features/minigames/modules/words/words_game_module.dart';

/// The games a duel can be played on. Each wraps the catalog's module, so
/// the tile, name and colours match the mini-game hub.
///
/// [id] is stored on the duel: never rename it once shipped.
enum DuelGame {
  memory(MemoryGameModule()),
  digits(DigitsGameModule()),
  words(WordsGameModule()),
  crossword(CrosswordGameModule());

  const DuelGame(this.module);

  final BaseMinigame module;

  String get id => module.id;
  String get titleKey => module.titleKey;
  IconData get icon => module.icon;
  MinigamePalette get palette => module.palette;

  /// Duels stored before games could be chosen have no id: they were
  /// played on the memory board.
  static DuelGame byId(String? id) =>
      values.where((game) => game.id == id).firstOrNull ?? memory;
}
