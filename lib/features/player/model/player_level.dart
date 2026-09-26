/// La aritmética de niveles del juego, en un único sitio.
///
/// El diseño anterior guardaba `level` y `currentXp` como dos campos
/// independientes en Firestore, y nadie escribía nunca `level`: el jugador se
/// quedaba en Nivel 1 con el XP creciendo sin límite y la barra de la Home
/// nunca se completaba.
///
/// Aquí el único dato que se persiste es **`totalXp`, acumulado de por vida y
/// monótono**. El nivel, el progreso de la barra y el XP que falta son
/// funciones puras de ese número. Eso arregla el bug y, de paso, elimina una
/// clase entera de conflictos de sincronización: un contador monótono se
/// resuelve con incrementos, mientras que un nivel almacenado en dos
/// dispositivos no se resuelve con nada.
library;

import 'dart:math' as math;

/// XP que hay que ganar **dentro** de [level] para alcanzar el siguiente.
///
/// Curva lineal: 1.000 XP para dejar atrás el nivel 1, 2.000 el nivel 2, etc.
/// Es la misma progresión que ya usaba el Perfil, conservada a propósito para
/// que ningún jugador note un salto al actualizar.
int xpForLevel(int level) => 1000 * (level < 1 ? 1 : level);

/// XP acumulado con el que arranca [level].
///
/// Σ(1000·n) para n < level, en forma cerrada: 500·(level−1)·level.
int totalXpAtLevelStart(int level) {
  if (level <= 1) return 0;
  return 500 * (level - 1) * level;
}

/// El nivel que corresponde a [totalXp].
int levelFromTotalXp(int totalXp) {
  if (totalXp <= 0) return 1;

  // Inversa de 500·(L−1)·L ≤ totalXp.
  var level = ((1 + math.sqrt(1 + totalXp / 125)) / 2).floor();
  if (level < 1) level = 1;

  // La raíz en coma flotante puede desviarse un nivel justo en los límites
  // exactos (un jugador con 45.000 XP clavados está estrenando el nivel 10,
  // no terminando el 9). La corrección es aritmética entera, que sí es exacta.
  while (totalXpAtLevelStart(level + 1) <= totalXp) {
    level++;
  }
  while (level > 1 && totalXpAtLevelStart(level) > totalXp) {
    level--;
  }
  return level;
}

/// XP conseguido dentro del nivel actual.
int xpIntoLevel(int totalXp) {
  if (totalXp <= 0) return 0;
  return totalXp - totalXpAtLevelStart(levelFromTotalXp(totalXp));
}

/// XP que falta para subir de nivel. Nunca negativo.
int xpToNextLevel(int totalXp) {
  final safeTotal = totalXp < 0 ? 0 : totalXp;
  final remaining =
      totalXpAtLevelStart(levelFromTotalXp(safeTotal) + 1) - safeTotal;
  return remaining < 0 ? 0 : remaining;
}

/// Progreso dentro del nivel actual, de 0.0 a 1.0.
double levelProgress(int totalXp) {
  final level = levelFromTotalXp(totalXp);
  final needed = xpForLevel(level);
  if (needed <= 0) return 0;
  return (xpIntoLevel(totalXp) / needed).clamp(0.0, 1.0);
}

/// Convierte el par heredado (`level`, `currentXp`) en un [totalXp].
///
/// Se aplica **una sola vez**, al leer un documento de Firestore que todavía
/// no tiene `totalXp`. Es determinista y solo depende de campos que ya están
/// en el documento, así que puede correr en el cliente sin coordinación.
///
/// Nota sobre las víctimas del bug: quien acumuló 45.000 XP atrapado en el
/// Nivel 1 no se queda ahí — al migrar recupera el Nivel 10, que es el que le
/// correspondía desde el principio.
int migratedTotalXp({required int legacyLevel, required int legacyCurrentXp}) {
  final level = legacyLevel < 1 ? 1 : legacyLevel;
  final withinLevel = legacyCurrentXp < 0 ? 0 : legacyCurrentXp;
  return totalXpAtLevelStart(level) + withinLevel;
}
