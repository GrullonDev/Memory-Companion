import 'package:memory_companion/features/game/board/model/memory_card.dart';

/// How cleanly one card was found, judged by how often it was turned over.
///
/// A card's first flip is usually discovery and its second the match, so
/// two flips is flawless play. Everyone gets the same board, so the grids
/// two players share are directly comparable, cell by cell.
enum CardRating {
  /// Found in at most two flips.
  sharp('🟩', 'g'),

  /// Three or four flips.
  close('🟨', 'y'),

  /// Five or more.
  struggled('🟥', 'r');

  const CardRating(this.emoji, this.code);

  final String emoji;

  /// One-letter storage code. Stable: never reuse a letter.
  final String code;

  static CardRating forFlips(int flips) {
    if (flips <= 2) return sharp;
    if (flips <= 4) return close;
    return struggled;
  }

  static CardRating fromCode(String code) =>
      values.firstWhere((r) => r.code == code, orElse: () => struggled);
}

/// A finished daily challenge: what the result screen and the share text
/// show, and what is stored so it can be shared again later in the day.
class DailyResult {
  const DailyResult({
    required this.dateKey,
    required this.number,
    required this.elapsedSeconds,
    required this.moves,
    required this.hintsUsed,
    required this.score,
    required this.columns,
    required this.grid,
  });

  factory DailyResult.fromBoard({
    required String dateKey,
    required int number,
    required List<MemoryCard> cards,
    required int columns,
    required int elapsedSeconds,
    required int moves,
    required int hintsUsed,
    required int score,
  }) {
    return DailyResult(
      dateKey: dateKey,
      number: number,
      elapsedSeconds: elapsedSeconds,
      moves: moves,
      hintsUsed: hintsUsed,
      score: score,
      columns: columns,
      grid: [for (final c in cards) CardRating.forFlips(c.flipCount)],
    );
  }

  final String dateKey;
  final int number;
  final int elapsedSeconds;
  final int moves;
  final int hintsUsed;
  final int score;

  /// Board width, so the emoji grid has the board's shape.
  final int columns;

  /// One rating per card, in board order.
  final List<CardRating> grid;

  /// Compact storage form, e.g. `'ggyg|gggr'`: rows joined by `|`.
  String get encodedGrid {
    final rows = <String>[];
    for (var i = 0; i < grid.length; i += columns) {
      rows.add(grid.skip(i).take(columns).map((r) => r.code).join());
    }
    return rows.join('|');
  }

  static ({int columns, List<CardRating> grid}) decodeGrid(String encoded) {
    final rows = encoded.split('|').where((r) => r.isNotEmpty).toList();
    return (
      columns: rows.isEmpty ? 1 : rows.first.length,
      grid: [
        for (final row in rows)
          for (final code in row.split('')) CardRating.fromCode(code),
      ],
    );
  }

  /// The grid as emoji lines, one per board row.
  List<String> get emojiRows {
    final rows = <String>[];
    for (var i = 0; i < grid.length; i += columns) {
      rows.add(grid.skip(i).take(columns).map((r) => r.emoji).join());
    }
    return rows;
  }
}
