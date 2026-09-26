/// Los premios de la escalera de niveles, en un único sitio.
///
/// Cada juego (`GameCategory`) tiene su propia escalera: empieza en el
/// Nivel 1 y sube un peldaño por cada tablero ganado (`SkillState.level`).
/// Cada [LevelRewards.every] niveles **completados** hay un regalo, y cada
/// [LevelRewards.chestEvery] ese regalo es un cofre que vale el doble.
///
/// Todo lo de aquí es aritmética pura sobre el número de niveles
/// completados, igual que `player_level.dart` lo es sobre el XP: lo único
/// que se persiste es hasta qué nivel ya se entregó el premio
/// (`CategoryLevels.rewardedLevel`), así que repetir el cálculo nunca puede
/// pagar dos veces el mismo peldaño.
library;

/// Un premio concreto de la escalera.
class LevelReward {
  const LevelReward({
    required this.level,
    required this.coins,
    required this.isChest,
  });

  /// El nivel que hay que **completar** para ganarlo.
  final int level;

  final int coins;

  /// Los cofres son los premios grandes; la UI los distingue del regalo.
  final bool isChest;

  @override
  bool operator ==(Object other) =>
      other is LevelReward &&
      other.level == level &&
      other.coins == coins &&
      other.isChest == isChest;

  @override
  int get hashCode => Object.hash(level, coins, isChest);

  @override
  String toString() =>
      'LevelReward(level: $level, coins: $coins, isChest: $isChest)';
}

abstract final class LevelRewards {
  /// Cada cuántos niveles completados hay premio.
  static const int every = 5;

  /// Cada cuántos niveles completados el premio es un cofre.
  static const int chestEvery = 10;

  /// Monedas por nivel del peldaño: el Nivel 5 da 100, el 15 da 300. Crece
  /// con la escalera para que el siguiente premio siempre apetezca.
  static const int _coinsPerLevel = 20;

  /// El premio por completar [level], o null si ese peldaño no tiene.
  static LevelReward? forCompletedLevel(int level) {
    if (level < every || level % every != 0) return null;
    final isChest = level % chestEvery == 0;
    final coins = level * _coinsPerLevel * (isChest ? 2 : 1);
    return LevelReward(level: level, coins: coins, isChest: isChest);
  }

  /// Los premios de los niveles completados en (`after`, `upTo`].
  ///
  /// Es lo que se entrega al reclamar: si el jugador ya cobró hasta el
  /// Nivel 5 y ahora ha completado el 12, le corresponde el del 10.
  static List<LevelReward> between({required int after, required int upTo}) {
    final rewards = <LevelReward>[];
    final start = after < 0 ? 0 : after;
    for (var level = start + 1; level <= upTo; level++) {
      final reward = forCompletedLevel(level);
      if (reward != null) rewards.add(reward);
    }
    return rewards;
  }

  /// El próximo premio para quien ha completado [completedLevels].
  static LevelReward nextAfter(int completedLevels) {
    final completed = completedLevels < 0 ? 0 : completedLevels;
    final next = (completed ~/ every + 1) * every;
    return forCompletedLevel(next)!;
  }

  /// Progreso hacia [nextAfter], de 0.0 a 1.0.
  static double progressTowardsNext(int completedLevels) {
    final completed = completedLevels < 0 ? 0 : completedLevels;
    return (completed % every) / every;
  }

  /// Niveles que faltan para [nextAfter]. Siempre entre 1 y [every].
  static int levelsUntilNext(int completedLevels) {
    final completed = completedLevels < 0 ? 0 : completedLevels;
    return nextAfter(completed).level - completed;
  }
}
