import 'dart:math';

import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';

/// A board that several players must be dealt identically: the daily
/// challenge, or both sides of a versus duel.
///
/// It fixes everything the adaptive engine would otherwise choose per
/// player, so results can be compared.
abstract interface class SharedBoard {
  GameCategory get category;
  DifficultySettings get settings;

  /// A fresh generator on every read, so dealing twice deals the same board.
  Random get random;
}
