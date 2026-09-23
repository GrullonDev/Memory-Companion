import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/hub/widget/minigame_tile.dart';

/// Registered mini-games laid out as a grid, for use inside a scrolling
/// parent.
///
/// Not a `GridView`: a grid forces one aspect ratio on every cell, which
/// clips tiles on small phones and with enlarged text. Rows of equal-height
/// tiles adapt instead — up to three columns on tablets, two on phones, one
/// when the screen is narrow or the text is large.
class MinigameGrid extends StatelessWidget {
  const MinigameGrid({super.key, required this.games});

  final List<BaseMinigame> games;

  /// Narrowest a tile can be and still read comfortably.
  static const double _minTileWidth = 150;
  static const int _maxColumns = 3;

  int _columnsFor(double width, double textScale) {
    if (textScale > 1.3) return 1;
    final fit =
        ((width + AppSpacing.gutter) / (_minTileWidth + AppSpacing.gutter))
            .floor();
    return fit.clamp(1, _maxColumns);
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth, textScale);
        final rows = <Widget>[];
        for (var start = 0; start < games.length; start += columns) {
          if (start > 0) rows.add(const SizedBox(height: AppSpacing.gutter));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      // Empty cells keep the last row's tiles the same width
                      // as the rows above.
                      child: start + i < games.length
                          ? MinigameTile(
                              game: games[start + i],
                              onTap: () => games[start + i].start(context),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(children: rows);
      },
    );
  }
}
