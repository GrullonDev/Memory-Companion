import 'dart:math';

import 'package:memory_companion/features/game/board/model/card_pair.dart';
import 'package:memory_companion/features/game/board/rules/match_rule.dart';

/// How demanding the *content* of a board is, independent of its size.
///
/// The adaptive engine raises it slowly as the player improves: sums within
/// ten become subtraction and then multiplication; picture-to-word pairs
/// give way to synonyms.
enum ContentTier { gentle, standard, challenging }

/// Everything a category needs to deal one board.
class DeckRequest {
  const DeckRequest({
    required this.pairCount,
    required this.tier,
    required this.languageCode,
    required this.random,
  });

  final int pairCount;
  final ContentTier tier;

  /// Words on the cards follow the app language ('es', 'en').
  final String languageCode;

  /// Injected so tests can deal a fixed board.
  final Random random;
}

/// A kind of memory game: what the cards show and what counts as a match.
///
/// To add a game mode, subclass this, implement [buildPairs], and register
/// the instance in `GameCategories.all`. The controller, the difficulty
/// engine and the board widgets need no changes.
abstract class GameCategory {
  const GameCategory();

  /// Stable identifier. Used for routing and to key the player's skill, so
  /// never rename it once shipped.
  String get id;

  /// `AppLocale` keys for the mode's name and one-line description.
  String get nameKey;
  String get descriptionKey;

  /// Board size bounds for this category. The adaptive engine moves inside
  /// them; [maxPairs] must not exceed what [buildPairs] can produce without
  /// repeating content.
  int get minPairs;
  int get maxPairs;

  /// How much longer than a picture it takes to take in one card. Scales
  /// preview time, time limit and mismatch reveal: reading "12 − 5" takes a
  /// moment that recognising 🍓 does not.
  double get readingLoad => 1.0;

  MatchRule get matchRule => const PairIdMatchRule();

  /// Returns exactly [DeckRequest.pairCount] pairs with unique `pairId`s.
  ///
  /// Implementations must also avoid ambiguity across pairs: no face may
  /// logically match a face from a different pair, or a correct answer
  /// would be scored as a mistake.
  List<CardPair> buildPairs(DeckRequest request);
}
