import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game/model/match_rewards.dart';

/// La única fórmula de recompensas. Estos tests son lo que impide que vuelva
/// a haber tres.
void main() {
  test('perder deja algo, pero no monedas', () {
    final rewards = calculateMatchRewards(
      score: 4000,
      moves: 8,
      timeLimit: 90,
      secondsElapsed: 10,
      won: false,
    );

    // Una sesión que no deja nada es una sesión que no invita a volver...
    expect(rewards.xp, 10);
    // ...pero el premio se gana.
    expect(rewards.coins, 0);
  });

  test('ninguna bonificación gana lo justo por el marcador', () {
    final rewards = calculateMatchRewards(
      score: 1200,
      moves: 20, // por encima del margen de eficiencia
      timeLimit: 90,
      secondsElapsed: 80, // más de la mitad del tiempo
      won: true,
    );

    expect(rewards.coins, 62, reason: '50 base + 1200~/100');
    expect(rewards.xp, 124, reason: '100 base + 1200~/50');
  });

  test('terminar rápido y limpio acumula ambas bonificaciones', () {
    final rewards = calculateMatchRewards(
      score: 1200,
      moves: 12,
      timeLimit: 90,
      secondsElapsed: 40,
      won: true,
    );

    expect(rewards.coins, 125);
    expect(rewards.xp, 201);
  });

  test('el margen de eficiencia corta donde debe', () {
    MatchRewards atMoves(int moves) => calculateMatchRewards(
          score: 1000,
          moves: moves,
          timeLimit: 90,
          secondsElapsed: 80,
          won: true,
        );

    expect(atMoves(13).coins - atMoves(14).coins, 50);
    expect(atMoves(13).xp - atMoves(14).xp, 50);
  });

  test('un tiempo límite de cero no rompe el cálculo', () {
    final rewards = calculateMatchRewards(
      score: 500,
      moves: 30,
      timeLimit: 0,
      secondsElapsed: 0,
      won: true,
    );

    expect(rewards.coins, 55);
    expect(rewards.xp, 110);
  });

  test('las recompensas se comparan por valor', () {
    expect(
      const MatchRewards(coins: 10, xp: 20),
      const MatchRewards(coins: 10, xp: 20),
    );
    expect(MatchRewards.none, const MatchRewards(coins: 0, xp: 0));
  });
}
