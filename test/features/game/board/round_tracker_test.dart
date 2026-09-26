import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game/board/model/card_face.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/board/rules/match_rule.dart';
import 'package:memory_companion/features/game/board/rules/round_tracker.dart';

MemoryCard _card(int id, String pair) =>
    MemoryCard(id: id, pairId: pair, face: TextFace('$pair$id'));

void main() {
  // a0 a1 b2 b3 c4 c5
  final board = [
    _card(0, 'a'), _card(1, 'a'),
    _card(2, 'b'), _card(3, 'b'),
    _card(4, 'c'), _card(5, 'c'),
  ];

  test('la regla por pairId empareja caras distintas del mismo par', () {
    const rule = PairIdMatchRule();
    expect(rule.isMatch(board[0], board[1]), isTrue);
    expect(rule.isMatch(board[0], board[0]), isFalse, reason: 'misma carta');
    expect(rule.isMatch(board[0], board[2]), isFalse);
  });

  test('fallar con cartas nunca vistas no es un error de memoria', () {
    final tracker = RoundTracker(const PairIdMatchRule());
    expect(tracker.recordTurn(board[0], board[2], board), isFalse);
    expect(tracker.memoryErrors, 0);
  });

  test('elegir una carta ya vista que no es la pareja sí lo es', () {
    final tracker = RoundTracker(const PairIdMatchRule())
      ..recordTurn(board[0], board[2], board);
    tracker.recordTurn(board[4], board[2], board);
    expect(tracker.memoryErrors, 1);
  });

  test('no ir a por la pareja ya vista también lo es', () {
    final tracker = RoundTracker(const PairIdMatchRule())
      ..recordTurn(board[0], board[2], board); // ya se vio b2
    tracker.recordTurn(board[3], board[4], board); // b3 y c4 son nuevas
    expect(tracker.memoryErrors, 1);
  });

  test('un acierto corta la racha de errores', () {
    final tracker = RoundTracker(const PairIdMatchRule())
      ..recordTurn(board[0], board[2], board)
      ..recordTurn(board[4], board[2], board)
      ..recordTurn(board[5], board[0], board);
    expect(tracker.consecutiveMemoryErrors, 2);
    tracker.recordTurn(board[4], board[5], board);
    expect(tracker.consecutiveMemoryErrors, 0);
    expect(tracker.memoryErrors, 2);
  });

  test('las cartas enseñadas por una pista cuentan como vistas', () {
    final tracker = RoundTracker(const PairIdMatchRule())..markSeen([0, 1]);
    tracker.recordTurn(board[2], board[0], board);
    expect(tracker.memoryErrors, 1);
  });
}
