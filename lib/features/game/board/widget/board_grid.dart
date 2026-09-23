import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/board/widget/memory_card_tile.dart';

class BoardGrid extends StatelessWidget {
  const BoardGrid({super.key, required this.cards, required this.onCardTap});

  final List<MemoryCard> cards;
  final ValueChanged<int> onCardTap;

  /// Few cards get big cards; a full board still fits a phone. Public so
  /// the daily challenge's share grid can take the same shape.
  static int columnsFor(int cardCount) {
    if (cardCount <= 6) return 3;
    if (cardCount <= 16) return 4;
    return 5;
  }

  /// The tallest a card may get relative to its width in the accessible
  /// profile. Taller cards are bigger targets; past this they stop looking
  /// like cards.
  static const double _minAspectRatio = 0.7;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final columns = columnsFor(cards.length);
    final gap = tokens.cardGridGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            childAspectRatio: tokens.isAccessible
                ? _fillingAspectRatio(constraints, columns, gap)
                : 1,
          ),
          itemBuilder: (context, index) {
            return MemoryCardTile(
              card: cards[index],
              position: index + 1,
              onTap: () => onCardTap(index),
            );
          },
        );
      },
    );
  }

  /// Width/height ratio that makes the cards fill the space the board has,
  /// rather than staying square and leaving a band of empty screen: every
  /// spare pixel becomes touch target.
  double _fillingAspectRatio(
    BoxConstraints constraints,
    int columns,
    double gap,
  ) {
    if (!constraints.hasBoundedHeight || cards.isEmpty) return 1;
    final rows = (cards.length / columns).ceil();
    final cellWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
    final cellHeight = (constraints.maxHeight - gap * (rows - 1)) / rows;
    if (cellWidth <= 0 || cellHeight <= 0) return 1;
    // Wider than tall is allowed too: that is what keeps a short screen
    // from overflowing.
    return math.max(cellWidth / cellHeight, _minAspectRatio);
  }
}
