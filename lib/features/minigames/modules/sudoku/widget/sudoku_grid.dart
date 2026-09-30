import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/model/sudoku_state.dart';

/// The sudoku board: thick lines between boxes, the selected cell and its
/// row, column and box tinted, clues in bold and a wrong entry flashed.
class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key, required this.state, required this.onSelect});

  final SudokuState state;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final shape = state.difficulty.shape;
    final selected = state.selected;
    final textTheme = Theme.of(context).textTheme;

    bool related(int i) =>
        selected != null &&
        (shape.rowOf(i) == shape.rowOf(selected) ||
            shape.colOf(i) == shape.colOf(selected) ||
            shape.boxOf(i) == shape.boxOf(selected));

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.onSurface, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            for (var row = 0; row < shape.size; row++)
              Expanded(
                child: Row(
                  children: [
                    for (var col = 0; col < shape.size; col++)
                      Expanded(
                        child: _Cell(
                          index: row * shape.size + col,
                          state: state,
                          related: related(row * shape.size + col),
                          thickRight:
                              col < shape.size - 1 &&
                              (col + 1) % shape.boxCols == 0,
                          thickBottom:
                              row < shape.size - 1 &&
                              (row + 1) % shape.boxRows == 0,
                          textStyle: shape.size > 6
                              ? textTheme.titleMedium
                              : textTheme.headlineSmall,
                          onTap: onSelect,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.state,
    required this.related,
    required this.thickRight,
    required this.thickBottom,
    required this.textStyle,
    required this.onTap,
  });

  final int index;
  final SudokuState state;
  final bool related;
  final bool thickRight;
  final bool thickBottom;
  final TextStyle? textStyle;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final value = state.cells[index];
    final given = state.isGiven(index);
    final isSelected = state.selected == index;
    final isWrong = state.wrongCell == index;
    final selectedValue = state.selected == null
        ? 0
        : state.cells[state.selected!];
    final sameValue = value != 0 && value == selectedValue;

    final background = isWrong
        ? AppColors.errorContainer
        : isSelected
        ? AppColors.skySoft
        : sameValue
        ? AppColors.sunSoft
        : related
        ? AppColors.surfaceContainerLow
        : AppColors.surface;

    return Semantics(
      button: true,
      selected: isSelected,
      label: value == 0 ? null : '$value',
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              right: BorderSide(
                color: thickRight
                    ? AppColors.onSurface
                    : AppColors.outlineVariant,
                width: thickRight ? 2 : 0.5,
              ),
              bottom: BorderSide(
                color: thickBottom
                    ? AppColors.onSurface
                    : AppColors.outlineVariant,
                width: thickBottom ? 2 : 0.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: value == 0
              ? null
              : FittedBox(
                  child: Text(
                    '$value',
                    style: textStyle?.copyWith(
                      fontWeight: given ? FontWeight.w800 : FontWeight.w500,
                      color: given ? AppColors.onSurface : AppColors.skyStrong,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
