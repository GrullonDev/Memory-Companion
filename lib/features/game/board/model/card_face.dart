/// What a card shows once it is turned over.
///
/// Sealed so the tile that renders it can switch exhaustively: adding a new
/// kind of face (an image asset, a sound) is a new subclass here plus one
/// branch in `MemoryCardTile`, and the compiler points at that branch.
sealed class CardFace {
  const CardFace();

  /// Text read aloud by screen readers when the card is face up.
  String get semanticLabel;
}

/// A single glyph drawn large: an emoji or a short symbol.
final class SymbolFace extends CardFace {
  const SymbolFace(this.symbol);

  final String symbol;

  @override
  String get semanticLabel => symbol;

  @override
  bool operator ==(Object other) =>
      other is SymbolFace && other.symbol == symbol;

  @override
  int get hashCode => symbol.hashCode;
}

/// A word or a short expression ("3 + 4", "Fast"), scaled to fit the card.
final class TextFace extends CardFace {
  const TextFace(this.text);

  final String text;

  @override
  String get semanticLabel => text;

  @override
  bool operator ==(Object other) => other is TextFace && other.text == text;

  @override
  int get hashCode => text.hashCode;
}
