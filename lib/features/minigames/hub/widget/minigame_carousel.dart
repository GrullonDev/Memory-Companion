import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/hub/widget/minigame_tile.dart';

/// Mini-games as a single horizontally scrolling row, for the Home.
///
/// A full grid grows the Home by a screen for every few games added; a row
/// stays one tile tall however many games exist, and the hub keeps the grid.
class MinigameCarousel extends StatelessWidget {
  const MinigameCarousel({super.key, required this.games});

  final List<BaseMinigame> games;

  static const double _tileWidth = 156;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Room for the tiles' shadows, which the scroll view would clip.
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < games.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.gutter),
              SizedBox(
                width: _tileWidth,
                child: MinigameTile(
                  game: games[i],
                  onTap: () => games[i].start(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
