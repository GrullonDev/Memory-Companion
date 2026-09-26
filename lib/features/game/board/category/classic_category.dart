import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/model/card_face.dart';
import 'package:memory_companion/features/game/board/model/card_pair.dart';

/// The original game: find two identical pictures.
///
/// Content difficulty comes from how alike the pictures are. Gentle boards
/// mix unrelated things (a strawberry, a car, a star), which are easy to
/// tell apart at a glance; harder boards draw from one family, where every
/// card is a fruit and shape and colour have to be remembered precisely.
class ClassicCategory extends GameCategory {
  const ClassicCategory();

  static const _distinct = [
    '🍓', '🐶', '🚗', '⭐', '🎈', '🌻', '🐟', '⚽', '🎁', '🌙', //
  ];

  static const _fruits = [
    '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍒', '🍑', '🥝', //
  ];

  @override
  String get id => 'classic';

  @override
  String get nameKey => 'categoryClassicName';

  @override
  String get descriptionKey => 'categoryClassicDescription';

  @override
  int get minPairs => 3;

  @override
  int get maxPairs => 10;

  @override
  List<CardPair> buildPairs(DeckRequest request) {
    final pool = switch (request.tier) {
      ContentTier.gentle => _distinct,
      // Half and half: a first taste of look-alikes.
      ContentTier.standard => [..._distinct.take(5), ..._fruits.take(5)],
      ContentTier.challenging => _fruits,
    };
    final symbols = [...pool]..shuffle(request.random);
    return [
      for (final symbol in symbols.take(request.pairCount))
        CardPair.identical(pairId: symbol, face: SymbolFace(symbol)),
    ];
  }
}
