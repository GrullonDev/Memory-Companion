import 'package:memory_companion/features/game/board/model/memory_card.dart';

/// Decides whether two face-up cards are a match.
///
/// Each `GameCategory` exposes one. The board controller only ever asks the
/// rule, so a future category with a different notion of "match" (any two
/// even numbers, any two animals) plugs in without touching the controller.
abstract interface class MatchRule {
  bool isMatch(MemoryCard first, MemoryCard second);
}

/// Two distinct cards match when they were dealt from the same `CardPair`.
///
/// Covers both identical pictures and logical associations, because the
/// deck builders give both cards of a pair the same `pairId`.
class PairIdMatchRule implements MatchRule {
  const PairIdMatchRule();

  @override
  bool isMatch(MemoryCard first, MemoryCard second) =>
      first.id != second.id && first.pairId == second.pairId;
}
