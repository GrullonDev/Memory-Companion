import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/versus/cpu/cpu_opponent.dart';
import 'package:memory_companion/features/versus/model/duel.dart';

void main() {
  DuelScore cpuResult(CpuLevel level, int seed) => CpuOpponent.play(
    seed: seed,
    pairCount: 6,
    timeLimitSeconds: 90,
    level: level,
  );

  test('the same board always gives the same result', () {
    final a = cpuResult(CpuLevel.normal, 42);
    final b = cpuResult(CpuLevel.normal, 42);
    expect((a.score, a.seconds, a.moves), (b.score, b.seconds, b.moves));
  });

  test('it finishes the board in a plausible number of moves', () {
    for (var seed = 0; seed < 50; seed++) {
      for (final level in CpuLevel.values) {
        final result = cpuResult(level, seed);
        // Perfect play needs one move per pair; with forgetting, never
        // beyond what blind guessing would take.
        expect(result.moves, inInclusiveRange(6, 60));
        expect(result.score, greaterThanOrEqualTo(0));
      }
    }
  });

  test('a better memory plays better on average', () {
    double averageMoves(CpuLevel level) {
      var total = 0;
      for (var seed = 0; seed < 200; seed++) {
        total += cpuResult(level, seed).moves;
      }
      return total / 200;
    }

    final easy = averageMoves(CpuLevel.easy);
    final normal = averageMoves(CpuLevel.normal);
    final hard = averageMoves(CpuLevel.hard);
    expect(easy, greaterThan(normal));
    expect(normal, greaterThan(hard));
  });
}
