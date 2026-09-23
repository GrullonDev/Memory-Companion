import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game/board/model/star_rating.dart';

void main() {
  int stars({
    bool won = true,
    required int moves,
    required int elapsed,
    int pairs = 6,
    int limit = 120,
  }) => StarRating.of(
    won: won,
    moves: moves,
    pairCount: pairs,
    elapsedSeconds: elapsed,
    timeLimitSeconds: limit,
  );

  test('quedarse sin tiempo no da estrellas', () {
    expect(stars(won: false, moves: 6, elapsed: 120), 0);
  });

  test('pocos movimientos y rápido: tres estrellas', () {
    expect(stars(moves: 12, elapsed: 60), 3);
  });

  test('una de las dos métricas excelente y la otra aceptable: tres', () {
    expect(stars(moves: 12, elapsed: 100), 3);
    expect(stars(moves: 18, elapsed: 30), 3);
  });

  test('ambas aceptables: dos estrellas', () {
    expect(stars(moves: 18, elapsed: 100), 2);
  });

  test('ganar, aunque sea lento y con muchos movimientos, da una', () {
    expect(stars(moves: 40, elapsed: 400), 1);
  });

  test('se mide por pareja: un tablero grande no se castiga más', () {
    expect(stars(pairs: 6, moves: 12, elapsed: 60), 3);
    expect(stars(pairs: 12, moves: 24, elapsed: 60), 3);
  });

  test('un tablero degenerado no divide entre cero', () {
    expect(stars(pairs: 0, moves: 0, elapsed: 0, limit: 0), 3);
  });
}
