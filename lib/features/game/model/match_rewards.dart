/// Lo que una partida entrega al jugador.
///
/// Antes esto era un `Map<String, int>` con accesos `rewards['coins']!`, y
/// existían **tres** cálculos distintos para el mismo evento: uno en
/// `BoardController` (lo que el jugador veía en el overlay), un `+50` fijo en
/// `BoardPage` (lo que sumaba el saldo) y otro en `Match.calculateRewards`
/// (lo que se guardaba). El jugador veía un número, cobraba otro y conservaba
/// un tercero.
///
/// Ahora hay una sola fórmula y un solo tipo.
class MatchRewards {
  const MatchRewards({required this.coins, required this.xp});

  /// Nada ganado: se usa como valor neutro y en modos aún sin recompensa.
  static const MatchRewards none = MatchRewards(coins: 0, xp: 0);

  final int coins;
  final int xp;

  @override
  bool operator ==(Object other) =>
      other is MatchRewards && other.coins == coins && other.xp == xp;

  @override
  int get hashCode => Object.hash(coins, xp);

  @override
  String toString() => 'MatchRewards(coins: $coins, xp: $xp)';
}

/// Número de movimientos por debajo del cual la partida se considera limpia.
///
/// Ocho pares se resuelven en ocho movimientos con memoria perfecta; el
/// margen de cinco reconoce el juego bueno sin exigir el juego imposible.
const int _optimalMoves = 8;
const int _efficiencyMargin = 5;

/// La única fórmula de recompensas del juego.
///
/// Perder también da algo —10 XP— porque una sesión que no deja nada es una
/// sesión que no invita a volver. Pero no da monedas: el premio se gana.
MatchRewards calculateMatchRewards({
  required int score,
  required int moves,
  required int timeLimit,
  required int secondsElapsed,
  required bool won,
}) {
  if (!won) return const MatchRewards(coins: 0, xp: 10);

  var coins = 50 + (score ~/ 100);
  var xp = 100 + (score ~/ 50);

  // Bonus por velocidad: terminar en menos de la mitad del tiempo.
  if (timeLimit > 0 && secondsElapsed < timeLimit ~/ 2) {
    final timeBonus = ((timeLimit - secondsElapsed) / timeLimit * 50).toInt();
    xp += timeBonus;
    coins += timeBonus ~/ 2;
  }

  // Bonus por eficiencia: pocas jugadas desperdiciadas.
  if (moves <= _optimalMoves + _efficiencyMargin) {
    coins += 50;
    xp += 50;
  }

  return MatchRewards(coins: coins, xp: xp);
}
