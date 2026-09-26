import 'package:memory_companion/features/game/board/model/card_face.dart';

/// A single card in the memory board.
///
/// [id] identifies this card on this board; [pairId] is shared with the one
/// card it matches. Whether two cards match is decided by the category's
/// `MatchRule`, never by comparing faces, so two different faces can match.
class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.pairId,
    required this.face,
    this.isFaceUp = false,
    this.isMatched = false,
    this.flipCount = 0,
  });

  final int id;
  final String pairId;
  final CardFace face;
  final bool isFaceUp;
  final bool isMatched;

  /// Times the player turned this card over. The preview and hints do not
  /// count; the daily challenge's share grid is built from this.
  final int flipCount;

  MemoryCard copyWith({bool? isFaceUp, bool? isMatched, int? flipCount}) {
    return MemoryCard(
      id: id,
      pairId: pairId,
      face: face,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
      flipCount: flipCount ?? this.flipCount,
    );
  }
}
