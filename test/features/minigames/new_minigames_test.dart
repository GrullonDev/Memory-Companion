import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/core/minigame_level.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';
import 'package:memory_companion/features/minigames/modules/colors/model/colors_state.dart';
import 'package:memory_companion/features/minigames/modules/crossword/model/crossword_levels.dart';
import 'package:memory_companion/features/minigames/modules/digits/model/digits_state.dart';
import 'package:memory_companion/features/minigames/modules/math/model/math_state.dart';
import 'package:memory_companion/features/minigames/modules/pattern/controller/pattern_controller.dart';
import 'package:memory_companion/features/minigames/modules/pattern/model/pattern_state.dart';
import 'package:memory_companion/features/minigames/modules/sequence/controller/sequence_controller.dart';
import 'package:memory_companion/features/minigames/modules/sequence/model/sequence_state.dart';
import 'package:memory_companion/features/minigames/modules/slide/model/slide_state.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/controller/sudoku_controller.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/model/sudoku_puzzle.dart';
import 'package:memory_companion/features/minigames/modules/sudoku/model/sudoku_state.dart';
import 'package:memory_companion/features/minigames/modules/words/model/words_state.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';

class _RecordingReporter implements MinigameResultReporter {
  final reports = <(BaseMinigame, MinigameResult)>[];

  @override
  Future<void> report(BaseMinigame game, MinigameResult result) async {
    reports.add((game, result));
  }
}

/// Whether [cells] breaks no row, column or box rule of [shape].
bool _valid(SudokuShape shape, List<int> cells) {
  bool unique(Iterable<int> group) {
    final values = group.where((v) => v != 0).toList();
    return values.toSet().length == values.length;
  }

  for (var k = 0; k < shape.size; k++) {
    final row = [
      for (var i = 0; i < shape.cellCount; i++)
        if (shape.rowOf(i) == k) cells[i],
    ];
    final col = [
      for (var i = 0; i < shape.cellCount; i++)
        if (shape.colOf(i) == k) cells[i],
    ];
    final box = [
      for (var i = 0; i < shape.cellCount; i++)
        if (shape.boxOf(i) == k) cells[i],
    ];
    if (!unique(row) || !unique(col) || !unique(box)) return false;
  }
  return true;
}

/// Brute-force solution count, capped at 2. Only for small grids.
int _solutions(SudokuShape shape, List<int> cells) {
  final i = cells.indexOf(0);
  if (i < 0) return 1;
  var found = 0;
  for (var v = 1; v <= shape.size && found < 2; v++) {
    cells[i] = v;
    if (_valid(shape, cells)) found += _solutions(shape, cells);
    cells[i] = 0;
  }
  return found;
}

void main() {
  test('la plataforma ofrece diez juegos, con el sudoku entre ellos', () {
    expect(MinigameRegistry.all, hasLength(10));
    expect(MinigameRegistry.byId('sudoku'), isNotNull);
  });

  group('sudoku', () {
    for (final shape in [
      SudokuShape.mini,
      SudokuShape.midi,
      SudokuShape.classic,
    ]) {
      test('reparte una solución válida de ${shape.size} × ${shape.size}', () {
        final puzzle = SudokuPuzzle.generate(
          shape: shape,
          holes: shape.cellCount ~/ 2,
          random: Random(shape.size),
        );
        expect(puzzle.solution, isNot(contains(0)));
        expect(_valid(shape, puzzle.solution), isTrue);
        for (var i = 0; i < shape.cellCount; i++) {
          if (puzzle.givens[i] != 0) {
            expect(puzzle.givens[i], puzzle.solution[i]);
          }
        }
        expect(puzzle.holes, greaterThan(0));
        expect(puzzle.holes, lessThanOrEqualTo(shape.cellCount ~/ 2));
      });
    }

    test('los sudokus pequeños tienen una única solución', () {
      for (var seed = 0; seed < 20; seed++) {
        final puzzle = SudokuPuzzle.generate(
          shape: SudokuShape.mini,
          holes: 10,
          random: Random(seed),
        );
        expect(_solutions(SudokuShape.mini, [...puzzle.givens]), 1);
      }
    });

    test(
      'la dificultad sube: tablero más grande, menos pistas, menos errores',
      () {
        var previous = SudokuDifficulty.forLevel(1);
        for (var level = 2; level <= 200; level++) {
          final next = SudokuDifficulty.forLevel(level);
          final harder =
              next.shape.size > previous.shape.size ||
              (next.shape == previous.shape && next.holes >= previous.holes);
          expect(harder, isTrue, reason: 'nivel $level');
          expect(next.maxMistakes, lessThanOrEqualTo(previous.maxMistakes));
          expect(next.maxMistakes, greaterThanOrEqualTo(1));
          previous = next;
        }
        expect(SudokuDifficulty.forLevel(1).shape, SudokuShape.mini);
        expect(SudokuDifficulty.forLevel(50).shape, SudokuShape.classic);
        expect(SudokuDifficulty.forLevel(50).holes, sudokuMaxHoles);
      },
    );

    ProviderContainer container(_RecordingReporter reporter) {
      final c = ProviderContainer(
        overrides: [
          minigameRandomProvider.overrideWithValue(Random(7)),
          minigameLevelOverrideProvider.overrideWithValue(1),
          minigameResultReporterProvider.overrideWithValue(reporter),
          statsClockProvider.overrideWithValue(() => DateTime(2026, 9, 30)),
        ],
      );
      c.listen(sudokuControllerProvider, (_, _) {});
      return c;
    }

    test('rellenar todo con los números correctos gana y lo registra', () {
      final reporter = _RecordingReporter();
      final c = container(reporter);
      final controller = c.read(sudokuControllerProvider.notifier)..start();
      var state = c.read(sudokuControllerProvider);
      final solution = state.puzzle!.solution;

      while (state.phase == SudokuPhase.playing) {
        controller
          ..select(state.cells.indexOf(0))
          ..enter(solution[state.cells.indexOf(0)]);
        state = c.read(sudokuControllerProvider);
      }

      expect(state.won, isTrue);
      final (game, result) = reporter.reports.single;
      expect(game.id, 'sudoku');
      expect(result.won, isTrue);
      expect(result.itemsSolved, result.itemCount);
      expect(result.errors, 0);
      c.dispose();
    });

    test('un número equivocado no se escribe y demasiados pierden', () {
      final reporter = _RecordingReporter();
      final c = container(reporter);
      final controller = c.read(sudokuControllerProvider.notifier)..start();
      final state = c.read(sudokuControllerProvider);
      final cell = state.cells.indexOf(0);
      final wrong =
          state.puzzle!.solution[cell] % state.difficulty.shape.size + 1;

      controller
        ..select(cell)
        ..enter(wrong);
      expect(c.read(sudokuControllerProvider).cells[cell], 0);
      expect(c.read(sudokuControllerProvider).mistakes, 1);
      expect(c.read(sudokuControllerProvider).wrongCell, cell);

      for (var i = 0; i < state.difficulty.maxMistakes; i++) {
        controller.enter(wrong);
      }
      expect(c.read(sudokuControllerProvider).phase, SudokuPhase.finished);
      expect(reporter.reports.single.$2.won, isFalse);
      c.dispose();
    });

    test('las pistas gratis rellenan una casilla', () async {
      final reporter = _RecordingReporter();
      final c = container(reporter);
      final controller = c.read(sudokuControllerProvider.notifier)..start();
      final before = c.read(sudokuControllerProvider).emptyCells;

      expect(await controller.hint(), isTrue);
      final after = c.read(sudokuControllerProvider);
      expect(after.emptyCells, before - 1);
      expect(after.hintsUsed, 1);
      expect(after.freeHintsLeft, after.difficulty.freeHints - 1);
      c.dispose();
    });
  });

  group('dificultad infinita', () {
    test(
      'cada juego se endurece o se mantiene al subir de nivel, sin fallar',
      () {
        for (var level = 1; level < 300; level++) {
          final w0 = WordsDifficulty.forLevel(level);
          final w1 = WordsDifficulty.forLevel(level + 1);
          expect(w1.listSize, greaterThanOrEqualTo(w0.listSize));
          expect(w1.studyMsPerWord, lessThanOrEqualTo(w0.studyMsPerWord));
          expect(w1.listSize, lessThanOrEqualTo(wordsMaxListSize));

          for (final mode in DigitsMode.values) {
            expect(
              digitsStartSpanAt(mode, level + 1),
              greaterThanOrEqualTo(digitsStartSpanAt(mode, level)),
            );
            expect(
              digitsTargetSpanAt(mode, level),
              lessThanOrEqualTo(digitsMaxSpan),
            );
            expect(
              digitsStartSpanAt(mode, level),
              lessThan(digitsTargetSpanAt(mode, level)),
            );
          }

          final s0 = SequenceDifficulty.forLevel(level);
          final s1 = SequenceDifficulty.forLevel(level + 1);
          expect(s1.pads, greaterThanOrEqualTo(s0.pads));
          expect(s1.startLength, greaterThanOrEqualTo(s0.startLength));
          expect(s1.flashMs, lessThanOrEqualTo(s0.flashMs));

          final p = PatternDifficulty.forLevel(level);
          expect(p.litCount, lessThanOrEqualTo(p.gridSize * p.gridSize ~/ 2));
          expect(p.litCount, greaterThanOrEqualTo(3));

          final m0 = MathDifficulty.forLevel(level);
          final m1 = MathDifficulty.forLevel(level + 1);
          expect(m1.ops.length, greaterThanOrEqualTo(m0.ops.length));
          expect(m1.timeLimitMs, lessThanOrEqualTo(m0.timeLimitMs));
          expect(m1.maxAddend, greaterThanOrEqualTo(m0.maxAddend));

          final c0 = ColorsDifficulty.forLevel(level);
          final c1 = ColorsDifficulty.forLevel(level + 1);
          expect(c1.colorCount, greaterThanOrEqualTo(c0.colorCount));
          expect(c1.timeLimitMs, lessThanOrEqualTo(c0.timeLimitMs));

          final l0 = SlideDifficulty.forLevel(level);
          final l1 = SlideDifficulty.forLevel(level + 1);
          expect(
            l1.size > l0.size || l1.shuffleMoves >= l0.shuffleMoves,
            isTrue,
          );
        }
      },
    );

    test('el crucigrama añade letras trampa en cada vuelta', () {
      expect(CrosswordLevels.decoysForLevel(1, puzzleCount: 12), 0);
      expect(CrosswordLevels.decoysForLevel(12, puzzleCount: 12), 0);
      expect(CrosswordLevels.decoysForLevel(13, puzzleCount: 12), 1);
      expect(CrosswordLevels.decoysForLevel(25, puzzleCount: 12), 2);
      expect(
        CrosswordLevels.decoysForLevel(1000, puzzleCount: 12),
        crosswordMaxDecoys,
      );
    });

    test('las palabras de nivel alto se estudian menos tiempo', () {
      expect(
        WordsDifficulty.forLevel(20).studyDuration,
        lessThan(WordsDifficulty.forLevel(5).studyDuration),
      );
    });
  });

  group('generadores', () {
    test('las operaciones son exactas, sin negativos y con 4 opciones', () {
      final random = Random(3);
      for (var level = 1; level < 60; level++) {
        final difficulty = MathDifficulty.forLevel(level);
        for (var i = 0; i < 20; i++) {
          final p = MathProblem.deal(difficulty, random);
          final expected = switch (p.op) {
            MathOp.add => p.a + p.b,
            MathOp.subtract => p.a - p.b,
            MathOp.multiply => p.a * p.b,
            MathOp.divide => p.a ~/ p.b,
          };
          expect(p.answer, expected);
          if (p.op == MathOp.divide) expect(p.a % p.b, 0);
          expect(p.answer, greaterThanOrEqualTo(0));
          expect(p.choices.toSet(), hasLength(4));
          expect(p.choices, contains(p.answer));
          expect(p.choices.every((c) => c >= 0), isTrue);
        }
      }
    });

    test('los colores trampa siempre escriben otro color', () {
      final random = Random(1);
      final difficulty = ColorsDifficulty.forLevel(40);
      var mismatches = 0;
      for (var i = 0; i < 500; i++) {
        final item = ColorsItem.deal(difficulty, random);
        expect(difficulty.colors, contains(item.ink));
        expect(difficulty.colors, contains(item.word));
        if (item.word != item.ink) mismatches++;
      }
      expect(
        mismatches,
        greaterThan(350),
        reason: '~${difficulty.mismatchPercent}%',
      );
    });

    test('el puzle deslizante llega barajado y se resuelve deshaciendo', () {
      for (final size in [3, 4, 5]) {
        final board = SlideBoard.shuffled(size, 80, Random(size));
        expect(board.solved, isFalse);
        expect(board.tiles.toSet(), hasLength(size * size));
        // Parity check: a board reached by legal slides is always solvable.
        var inversions = 0;
        final tiles = board.tiles.where((t) => t != 0).toList();
        for (var i = 0; i < tiles.length; i++) {
          for (var j = i + 1; j < tiles.length; j++) {
            if (tiles[i] > tiles[j]) inversions++;
          }
        }
        final gapRowFromBottom = size - board.gap ~/ size;
        final solvable = size.isOdd
            ? inversions.isEven
            : (inversions + gapRowFromBottom).isOdd;
        expect(solvable, isTrue, reason: '$size × $size');
      }
    });

    test('solo se deslizan las fichas junto al hueco', () {
      final board = SlideBoard.solved(3);
      expect(board.slide(0), isNull);
      final moved = board.slide(7)!;
      expect(moved.gap, 7);
      expect(moved.tiles[8], 8);
    });
  });

  group('controladores con tiempo', () {
    void run(
      void Function(FakeAsync async, ProviderContainer c, _RecordingReporter r)
      body,
    ) {
      fakeAsync((async) {
        final reporter = _RecordingReporter();
        final start = DateTime(2026, 9, 30, 10);
        final c = ProviderContainer(
          overrides: [
            minigameRandomProvider.overrideWithValue(Random(11)),
            minigameLevelOverrideProvider.overrideWithValue(1),
            minigameResultReporterProvider.overrideWithValue(reporter),
            statsClockProvider.overrideWithValue(
              () => start.add(async.elapsed),
            ),
          ],
        );
        c.listen(sequenceControllerProvider, (_, _) {});
        c.listen(patternControllerProvider, (_, _) {});
        body(async, c, reporter);
        c.dispose();
      });
    }

    test('secuencia: repetir hasta la meta gana', () {
      run((async, c, reporter) {
        final controller = c.read(sequenceControllerProvider.notifier)..start();
        var guard = 0;
        while (c.read(sequenceControllerProvider).phase !=
                SequencePhase.finished &&
            guard++ < 2000) {
          final state = c.read(sequenceControllerProvider);
          if (state.phase == SequencePhase.input) {
            for (final pad in state.sequence) {
              controller.tap(pad);
            }
          }
          async.elapse(const Duration(milliseconds: 100));
        }
        final state = c.read(sequenceControllerProvider);
        expect(state.won, isTrue);
        expect(state.bestLength, state.difficulty.targetLength);
        expect(reporter.reports.single.$2.won, isTrue);
      });
    });

    test('secuencia: dos fallos seguidos terminan la ronda', () {
      run((async, c, reporter) {
        final controller = c.read(sequenceControllerProvider.notifier)..start();
        for (var miss = 0; miss < sequenceMaxMisses; miss++) {
          while (c.read(sequenceControllerProvider).phase !=
              SequencePhase.input) {
            async.elapse(const Duration(milliseconds: 50));
          }
          final state = c.read(sequenceControllerProvider);
          controller.tap((state.sequence.first + 1) % state.difficulty.pads);
          async.elapse(sequenceFeedbackDuration);
        }
        expect(
          c.read(sequenceControllerProvider).phase,
          SequencePhase.finished,
        );
        expect(reporter.reports.single.$2.won, isFalse);
      });
    });

    test('patrones: encontrar todas las casillas gana', () {
      run((async, c, reporter) {
        final controller = c.read(patternControllerProvider.notifier)..start();
        async.elapse(PatternDifficulty.forLevel(1).showDuration);
        final state = c.read(patternControllerProvider);
        expect(state.phase, PatternPhase.input);
        for (final cell in state.lit) {
          controller.tap(cell);
        }
        expect(c.read(patternControllerProvider).won, isTrue);
        expect(reporter.reports.single.$2.itemsSolved, state.lit.length);
      });
    });

    test('patrones: pasarse de errores pierde', () {
      run((async, c, reporter) {
        final controller = c.read(patternControllerProvider.notifier)..start();
        controller.hide();
        final state = c.read(patternControllerProvider);
        final dark = [
          for (var i = 0; i < 9; i++)
            if (!state.lit.contains(i)) i,
        ];
        for (final cell in dark.take(state.difficulty.allowedErrors + 1)) {
          controller.tap(cell);
        }
        expect(c.read(patternControllerProvider).phase, PatternPhase.finished);
        expect(reporter.reports.single.$2.won, isFalse);
      });
    });
  });
}
