import 'package:flutter/material.dart';

import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/board/widget/memory_card_tile.dart';

class BoardGrid extends StatelessWidget {
  const BoardGrid({super.key, required this.cards, required this.onCardTap});

  final List<MemoryCard> cards;
  final ValueChanged<int> onCardTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return MemoryCardTile(
          card: cards[index],
          onTap: () => onCardTap(index),
        );
      },
    );
  }
}
