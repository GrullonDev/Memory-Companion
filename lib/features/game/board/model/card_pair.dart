import 'package:memory_companion/features/game/board/model/card_face.dart';

/// Two faces that belong together on the board.
///
/// In the classic mode both faces are the same picture; in the logic modes
/// they are different but related ("3 + 4" and "7", "Fire" and "Smoke").
/// [pairId] is what ties the two resulting cards together, so it must be
/// unique within one board.
class CardPair {
  const CardPair({
    required this.pairId,
    required this.first,
    required this.second,
  });

  /// A pair whose two cards show the same face.
  const CardPair.identical({required this.pairId, required CardFace face})
    : first = face,
      second = face;

  final String pairId;
  final CardFace first;
  final CardFace second;
}
