import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/board/rules/match_rule.dart';

/// Tells memory errors apart from unavoidable discovery flips.
///
/// Turning over a card nobody has seen yet and missing is not a mistake:
/// there was no way to know. Counting every mismatch as an error would read
/// a careful 70-year-old exploring the board as "struggling" and make the
/// game easier for no reason. A mismatch only counts as a memory error when
/// the player had already seen what they needed:
///
///  * the second card had been seen before, so they should have known it
///    was not the partner; or
///  * the first card's partner had been seen before, so they could have
///    picked it.
class RoundTracker {
  RoundTracker(this._rule);

  final MatchRule _rule;
  final Set<int> _seen = {};

  int _memoryErrors = 0;
  int _consecutiveMemoryErrors = 0;

  int get memoryErrors => _memoryErrors;

  /// Memory errors in a row since the last match. Used to relax the
  /// mismatch reveal time mid-round when the player is losing the thread.
  int get consecutiveMemoryErrors => _consecutiveMemoryErrors;

  /// Records a resolved turn of two cards. Returns whether it was a match.
  bool recordTurn(MemoryCard first, MemoryCard second, List<MemoryCard> board) {
    final isMatch = _rule.isMatch(first, second);

    if (isMatch) {
      _consecutiveMemoryErrors = 0;
    } else {
      final partnerSeen = board.any(
        (c) => _rule.isMatch(first, c) && _seen.contains(c.id),
      );
      if (_seen.contains(second.id) || partnerSeen) {
        _memoryErrors++;
        _consecutiveMemoryErrors++;
      }
    }

    _seen
      ..add(first.id)
      ..add(second.id);
    return isMatch;
  }

  /// Cards shown by a hint count as seen: missing them later is on memory.
  void markSeen(Iterable<int> cardIds) => _seen.addAll(cardIds);
}
