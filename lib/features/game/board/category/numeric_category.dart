import 'dart:math';

import 'package:memory_companion/features/game/board/category/game_category.dart';
import 'package:memory_companion/features/game/board/model/card_face.dart';
import 'package:memory_companion/features/game/board/model/card_pair.dart';

/// Match an operation with its result: "3 + 4" goes with "7".
///
/// Every result on a board is different. If two pairs shared a result, the
/// player would pair "3 + 4" with the other "7", be right, and be told they
/// were wrong.
class NumericCategory extends GameCategory {
  const NumericCategory();

  @override
  String get id => 'numeric';

  @override
  String get nameKey => 'categoryNumericName';

  @override
  String get descriptionKey => 'categoryNumericDescription';

  @override
  int get minPairs => 3;

  /// Capped by the gentle range: results 2 to 10 give nine distinct values.
  @override
  int get maxPairs => 8;

  /// Working out a sum takes longer than recognising a picture.
  @override
  double get readingLoad => 1.5;

  @override
  List<CardPair> buildPairs(DeckRequest request) {
    final random = request.random;
    final (minResult, maxResult) = switch (request.tier) {
      ContentTier.gentle => (2, 10),
      ContentTier.standard => (2, 20),
      ContentTier.challenging => (4, 40),
    };

    final results = [for (var r = minResult; r <= maxResult; r++) r]
      ..shuffle(random);

    return [
      for (final result in results.take(request.pairCount))
        CardPair(
          pairId: 'n$result',
          first: TextFace(_expressionFor(result, request.tier, random)),
          second: TextFace('$result'),
        ),
    ];
  }

  /// Builds an operation equal to [result]. Operands are always at least 1,
  /// so a card never reads "0 + 7".
  static String _expressionFor(int result, ContentTier tier, Random random) {
    String addition() {
      final a = 1 + random.nextInt(result - 1);
      return '$a + ${result - a}';
    }

    String subtraction() {
      final b = 1 + random.nextInt(9);
      return '${result + b} − $b';
    }

    String? multiplication() {
      final factors = [
        for (var a = 2; a <= 9; a++)
          if (result % a == 0 && result ~/ a >= 2 && result ~/ a <= 10) a,
      ];
      if (factors.isEmpty) return null;
      final a = factors[random.nextInt(factors.length)];
      return '$a × ${result ~/ a}';
    }

    return switch (tier) {
      ContentTier.gentle => addition(),
      ContentTier.standard => random.nextBool() ? addition() : subtraction(),
      ContentTier.challenging => switch (random.nextInt(3)) {
        0 => multiplication() ?? subtraction(),
        1 => subtraction(),
        _ => addition(),
      },
    };
  }
}
