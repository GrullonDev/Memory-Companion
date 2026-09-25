import 'dart:math';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/versus/model/duel.dart';

/// How well the computer remembers the cards it has seen.
enum CpuLevel {
  easy(recall: 0.35, secondsPerMove: 3.0, labelKey: AppLocale.cpuLevelEasy),
  normal(recall: 0.6, secondsPerMove: 2.4, labelKey: AppLocale.cpuLevelNormal),
  hard(recall: 0.85, secondsPerMove: 1.8, labelKey: AppLocale.cpuLevelHard);

  const CpuLevel({
    required this.recall,
    required this.secondsPerMove,
    required this.labelKey,
  });

  /// Chance that a card seen face up is remembered.
  final double recall;

  /// Average thinking and flipping time per move.
  final double secondsPerMove;
  final String labelKey;
}

/// The computer's side of a duel against the player.
///
/// The computer "plays" the same number of pairs as the player's board,
/// with a memory that forgets: every card it sees is remembered with
/// [CpuLevel.recall] probability. Its moves and time come out of that game
/// and are scored with the board's formula, so beating it means playing
/// the board better, not beating a made-up number.
///
/// Seeded by the duel, so a given board always gives the same result: the
/// computer cannot be re-rolled by leaving and coming back.
abstract final class CpuOpponent {
  static DuelScore play({
    required int seed,
    required int pairCount,
    required int timeLimitSeconds,
    required CpuLevel level,
  }) {
    final random = Random(seed ^ level.index);
    final cards = [
      for (var pair = 0; pair < pairCount; pair++) ...[pair, pair],
    ]..shuffle(random);

    final matched = List.filled(cards.length, false);
    final known = <int, int>{}; // position -> pair seen there
    var moves = 0;

    void see(int position) {
      if (random.nextDouble() < level.recall) {
        known[position] = cards[position];
      }
    }

    int? knownPartnerOf(int position) {
      for (final entry in known.entries) {
        if (entry.key != position &&
            !matched[entry.key] &&
            entry.value == cards[position]) {
          return entry.key;
        }
      }
      return null;
    }

    int unseen({int? except}) {
      final options = [
        for (var i = 0; i < cards.length; i++)
          if (!matched[i] && !known.containsKey(i) && i != except) i,
      ];
      if (options.isNotEmpty) return options[random.nextInt(options.length)];
      // Everything left has been seen: pick any other card still down.
      final rest = [
        for (var i = 0; i < cards.length; i++)
          if (!matched[i] && i != except) i,
      ];
      return rest[random.nextInt(rest.length)];
    }

    void match(int a, int b) {
      matched[a] = matched[b] = true;
      known
        ..remove(a)
        ..remove(b);
    }

    while (matched.contains(false)) {
      moves++;

      // A pair it already knows both halves of.
      final knownPair = known.keys
          .where((p) => !matched[p])
          .map((p) => (p, knownPartnerOf(p)))
          .where((e) => e.$2 != null)
          .firstOrNull;
      if (knownPair != null) {
        match(knownPair.$1, knownPair.$2!);
        continue;
      }

      final first = unseen();
      final partner = knownPartnerOf(first);
      if (partner != null) {
        match(first, partner);
        continue;
      }
      final second = unseen(except: first);
      if (cards[first] == cards[second]) {
        match(first, second);
      } else {
        see(first);
        see(second);
      }
    }

    final jitter = 0.85 + random.nextDouble() * 0.3;
    final seconds = (moves * level.secondsPerMove * jitter).round();
    final remaining = max(0, timeLimitSeconds - seconds);
    // Same formula as `BoardState.score`.
    final score = max(0, pairCount * 500 + remaining * 10 - moves * 15);
    return DuelScore(score: score, seconds: seconds, moves: moves);
  }
}
