import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/model/sudoku_puzzle.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/model/sudoku_state.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/sudoku_game_module.dart';
import 'package:memory_companion/features/shop/controller/store_controller.dart';
import 'package:memory_companion/features/shop/model/store_item.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

/// Runs a sudoku round: deal a puzzle for the level, take numbers, count
/// mistakes and hints.
///
/// A right number stays; a wrong one is rejected and counts as a mistake,
/// so the grid never holds an error the player has to hunt for. One round
/// is one stats row: cells to fill, cells filled, numbers entered.
class SudokuController extends Notifier<SudokuState> {
  static const _game = SudokuGameModule();

  late DateTime _startedAt;

  @override
  SudokuState build() {
    ref.listen(minigameLevelProvider(_game), (_, _) {});
    return SudokuState.intro(level: ref.read(minigameLevelProvider(_game)));
  }

  /// Deals a puzzle at [level], the player's ladder level by default.
  void start({int? level}) {
    final difficulty = SudokuDifficulty.forLevel(
      level ?? ref.read(minigameLevelProvider(_game)),
    );
    final puzzle = SudokuPuzzle.generate(
      shape: difficulty.shape,
      holes: difficulty.holes,
      random: ref.read(minigameRandomProvider),
    );
    _startedAt = ref.read(statsClockProvider)();
    state = SudokuState(
      phase: SudokuPhase.playing,
      difficulty: difficulty,
      puzzle: puzzle,
      cells: [...puzzle.givens],
      selected: puzzle.givens.indexOf(0),
    );
  }

  void retry() => start(level: state.level);
  void nextLevel() => start(level: state.level + 1);

  void select(int index) {
    if (state.phase != SudokuPhase.playing) return;
    state = state.copyWith(selected: () => index, wrongCell: () => null);
  }

  /// Writes [value] in the selected cell.
  void enter(int value) {
    final index = state.selected;
    if (state.phase != SudokuPhase.playing || index == null) return;
    if (state.cells[index] != 0) return;

    if (state.puzzle!.solution[index] == value) {
      final cells = [...state.cells]..[index] = value;
      _update(
        state.copyWith(
          cells: cells,
          entries: state.entries + 1,
          wrongCell: () => null,
          selected: () => _nextEmpty(cells, index),
        ),
      );
    } else {
      final next = state.copyWith(
        mistakes: state.mistakes + 1,
        entries: state.entries + 1,
        wrongCell: () => index,
      );
      state = next;
      if (next.mistakes > next.difficulty.maxMistakes) _finish();
    }
  }

  /// Fills the selected cell (or any empty one) with its number. Free up to
  /// the level's [SudokuDifficulty.freeHints]; after that each hint spends
  /// one bought in the store. Returns `false` when no hint was available.
  Future<bool> hint() async {
    if (state.phase != SudokuPhase.playing) return false;
    if (state.freeHintsLeft == 0) {
      final paid = await ref.read(storeServiceProvider).use(InventoryKind.hint);
      if (!paid || !ref.mounted || state.phase != SudokuPhase.playing) {
        return false;
      }
    }
    final selected = state.selected;
    final index = selected != null && state.cells[selected] == 0
        ? selected
        : state.cells.indexOf(0);
    if (index < 0) return false;
    final cells = [...state.cells]..[index] = state.puzzle!.solution[index];
    _update(
      state.copyWith(
        cells: cells,
        hintsUsed: state.hintsUsed + 1,
        wrongCell: () => null,
        selected: () => _nextEmpty(cells, index),
      ),
    );
    return true;
  }

  int? _nextEmpty(List<int> cells, int from) {
    for (var step = 1; step <= cells.length; step++) {
      final i = (from + step) % cells.length;
      if (cells[i] == 0) return i;
    }
    return null;
  }

  void _update(SudokuState next) {
    state = next;
    if (next.solved) _finish();
  }

  void _finish() {
    state = state.copyWith(phase: SudokuPhase.finished);
    final seconds = ref
        .read(statsClockProvider)()
        .difference(_startedAt)
        .inSeconds;
    unawaited(
      ref
          .read(minigameResultReporterProvider)
          .report(
            _game,
            MinigameResult(
              itemCount: state.holes,
              itemsSolved: state.filled,
              attempts: state.entries,
              errors: state.mistakes,
              hintsUsed: state.hintsUsed,
              secondsElapsed: max(0, seconds),
              won: state.won,
              score: state.won ? state.score : 0,
            ),
          ),
    );
  }
}

final sudokuControllerProvider =
    NotifierProvider.autoDispose<SudokuController, SudokuState>(
      SudokuController.new,
    );
