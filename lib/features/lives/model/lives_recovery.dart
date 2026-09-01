/// Recuperación de vidas por reloj, como función pura.
///
/// El diseño anterior mantenía las vidas solo en memoria con un `Timer`: al
/// cerrar la app volvían a estar las cinco, y el temporizador de recarga solo
/// corría mientras la app estaba abierta. La economía era evitable sin querer
/// y el contador mentía.
///
/// Aquí solo se guardan dos datos —cuántas vidas quedaban y cuándo empezó a
/// contar la recarga— y todo lo demás se deduce del reloj al arrancar.
library;

/// Estado de las vidas en un instante concreto.
class LivesSnapshot {
  const LivesSnapshot({
    required this.current,
    required this.lastRefillAt,
    required this.secondsUntilNextLife,
  });

  final int current;

  /// Momento desde el que cuenta la recarga en curso.
  final DateTime lastRefillAt;

  /// Segundos que faltan para la siguiente vida. 0 si ya están todas.
  final int secondsUntilNextLife;
}

/// Calcula cuántas vidas tiene el jugador *ahora*, partiendo de lo guardado.
///
/// Casos que cubre:
///
///  * **App cerrada mucho tiempo** — se recuperan todas las vidas que quepan
///    en el tiempo transcurrido, hasta el máximo.
///  * **Recarga a medias** — se conserva el resto: quien volvió a los 25
///    minutos con recarga de 20 no pierde los 5 minutos ya cumplidos.
///  * **Reloj hacia atrás** — no se regala nada ni se rompe el cálculo.
LivesSnapshot recoverLives({
  required int storedCurrent,
  required DateTime storedLastRefillAt,
  required DateTime now,
  required int maxLives,
  required Duration refillInterval,
}) {
  final current = storedCurrent < 0 ? 0 : storedCurrent;

  if (current >= maxLives) {
    return LivesSnapshot(
      current: maxLives,
      lastRefillAt: now,
      secondsUntilNextLife: 0,
    );
  }

  final elapsed = now.difference(storedLastRefillAt);
  final intervalSeconds = refillInterval.inSeconds;

  // El reloj se movió hacia atrás: se congela el progreso en vez de premiarlo.
  if (elapsed.isNegative || intervalSeconds <= 0) {
    return LivesSnapshot(
      current: current,
      lastRefillAt: storedLastRefillAt,
      secondsUntilNextLife: intervalSeconds,
    );
  }

  final recovered = elapsed.inSeconds ~/ intervalSeconds;
  final next = current + recovered;

  if (next >= maxLives) {
    return LivesSnapshot(
      current: maxLives,
      lastRefillAt: now,
      secondsUntilNextLife: 0,
    );
  }

  // Se arrastra el resto de la recarga en curso: el tiempo ya cumplido no se
  // tira, que es lo que haría reiniciar el contador en cada arranque.
  final consumedSeconds = recovered * intervalSeconds;
  final carriedLastRefill = storedLastRefillAt.add(
    Duration(seconds: consumedSeconds),
  );
  final remaining =
      intervalSeconds - now.difference(carriedLastRefill).inSeconds;

  return LivesSnapshot(
    current: next,
    lastRefillAt: carriedLastRefill,
    secondsUntilNextLife: remaining < 0 ? 0 : remaining,
  );
}
