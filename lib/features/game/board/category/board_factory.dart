import 'dart:math';

import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/difficulty/difficulty_settings.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';

/// Deals a shuffled board for any [GameCategory].
///
/// The category decides what the pairs are; this turns them into cards the
/// same way for every mode, and checks the contract categories must keep.
abstract final class BoardFactory {
  static List<MemoryCard> deal({
    required GameCategory category,
    required DifficultySettings settings,
    required String languageCode,
    required Random random,
  }) {
    final pairs = category.buildPairs(
      DeckRequest(
        pairCount: settings.pairCount,
        tier: settings.tier,
        languageCode: languageCode,
        random: random,
      ),
    );

    assert(
      pairs.length == settings.pairCount,
      '${category.id} dealt ${pairs.length} pairs, '
      'expected ${settings.pairCount}',
    );
    assert(
      pairs.map((p) => p.pairId).toSet().length == pairs.length,
      '${category.id} dealt duplicate pair ids',
    );

    final faces = [
      for (final pair in pairs) ...[
        (pair.pairId, pair.first),
        (pair.pairId, pair.second),
      ],
    ]..shuffle(random);

    return [
      for (var i = 0; i < faces.length; i++)
        MemoryCard(id: i, pairId: faces[i].$1, face: faces[i].$2),
    ];
  }
}
