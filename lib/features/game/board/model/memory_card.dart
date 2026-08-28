/// A single card in the memory board.
class MemoryCard {
  const MemoryCard({
    required this.id,
    required this.symbol,
    this.isFaceUp = false,
    this.isMatched = false,
  });

  final int id;
  final String symbol;
  final bool isFaceUp;
  final bool isMatched;

  MemoryCard copyWith({bool? isFaceUp, bool? isMatched}) {
    return MemoryCard(
      id: id,
      symbol: symbol,
      isFaceUp: isFaceUp ?? this.isFaceUp,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}
