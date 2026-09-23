import 'package:memory_companion/features/game/board/category/association_category.dart';
import 'package:memory_companion/features/game/board/category/classic_category.dart';
import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/category/numeric_category.dart';

/// Registry of every playable category. The one place to touch when adding
/// a game mode.
abstract final class GameCategories {
  static const classic = ClassicCategory();
  static const numeric = NumericCategory();
  static const association = AssociationCategory();

  static const List<GameCategory> all = [classic, numeric, association];

  /// Unknown ids fall back to the classic game rather than failing: an old
  /// deep link or a removed mode should still open a playable board.
  static GameCategory byId(String? id) =>
      all.firstWhere((c) => c.id == id, orElse: () => classic);
}
