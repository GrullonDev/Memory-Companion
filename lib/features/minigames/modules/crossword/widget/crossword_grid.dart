import 'dart:math';

import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/success_pulse.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_layout.dart';

/// The crossword: an empty tile for every hidden letter, the letter itself
/// once revealed. [highlight] marks the word just found, and its tiles pop
/// each time [highlightId] changes.
///
/// Hidden from screen readers: tiles alone mean nothing when read out, and
/// the screen announces progress in words instead.
class CrosswordGrid extends StatelessWidget {
  const CrosswordGrid({
    super.key,
    required this.layout,
    required this.revealed,
    this.highlight = const {},
    this.highlightId,
  });

  final CrosswordLayout layout;
  final Set<GridPos> revealed;
  final Set<GridPos> highlight;

  /// Identifies the find [highlight] belongs to. A new value replays the
  /// pop; rebuilding with the same one (a shuffle, a hint) does not.
  final Object? highlightId;

  static const _maxCell = 48.0;
  static const _gap = 4.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = min(_maxCell, constraints.maxWidth / layout.cols);
          final textStyle = Theme.of(context).textTheme.titleLarge;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var row = 0; row < layout.rows; row++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var col = 0; col < layout.cols; col++)
                        SizedBox.square(
                          dimension: cell,
                          child: _tile((row, col), textStyle),
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget? _tile(GridPos pos, TextStyle? textStyle) {
    final letter = layout.letters[pos];
    if (letter == null) return null;
    final shown = revealed.contains(pos);
    final fresh = highlight.contains(pos);

    return SuccessPulse(
      trigger: fresh ? highlightId : null,
      color: AppColors.streak,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.all(_gap / 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fresh
              ? AppColors.streak
              : shown
              ? AppColors.sun
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: shown
            ? FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  child: Text(
                    letter,
                    style: textStyle?.copyWith(
                      color: fresh ? AppColors.onStreak : AppColors.onSun,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
