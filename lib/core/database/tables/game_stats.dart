import 'package:drift/drift.dart';

/// Métricas de una partida terminada, para el panel de estadísticas.
///
/// Es una tabla **solo local**, a propósito separada de `Matches`: aquella
/// existe para sincronizarse con la nube y guarda recompensas; esta guarda
/// cómo jugó la memoria (errores, pistas, tamaño del tablero) y no sale
/// nunca del dispositivo. No pasa por la cola de sincronización ni referencia
/// a `PlayerProfiles`: el dispositivo tiene un único jugador y las
/// estadísticas no deben depender de que el perfil ya esté resuelto.
///
/// Las columnas son las **sumas** que necesita el análisis, no ratios: la
/// precisión de una semana es `Σ matchedPairs / Σ moves`, no la media de las
/// precisiones de cada partida, que pesaría igual un tablero de 3 parejas que
/// uno de 12. Por eso [accuracy] no se guarda: se deriva.
@DataClassName('GameStatsRow')
@TableIndex(name: 'idx_game_stats_played_at', columns: {#playedAt})
@TableIndex(name: 'idx_game_stats_played_day', columns: {#playedDay})
class GameStats extends Table {
  /// Autoincremental: además de clave sirve de cursor para paginar el
  /// historial sin `OFFSET`, que se vuelve lento con cientos de filas.
  IntColumn get id => integer().autoIncrement()();

  /// Reloj local en milisegundos.
  IntColumn get playedAt => integer()();

  /// `'YYYY-MM-DD'` en zona **local**, igual que `lastPlayedDate` del perfil:
  /// agrupar por día y calcular la racha no puede depender del huso horario
  /// en el que se consulte.
  TextColumn get playedDay => text()();

  /// `GameCategory.id`.
  TextColumn get categoryId => text()();

  IntColumn get pairCount => integer()();
  IntColumn get matchedPairs => integer()();

  /// Turnos: cada par de cartas volteadas cuenta uno.
  IntColumn get moves => integer()();

  /// Fallos con información disponible, según `RoundTracker`. Los fallos de
  /// descubrimiento no cuentan.
  IntColumn get memoryErrors => integer()();
  IntColumn get hintsUsed => integer()();

  /// Tiempo real jugado, incluida la prórroga de una partida sin reloj.
  IntColumn get secondsElapsed => integer()();
  IntColumn get timeLimitSeconds => integer()();
  BoolColumn get timed => boolean()();

  BoolColumn get won => boolean()();
  IntColumn get score => integer()();

  /// `Places.id` donde se jugó, si el jugador activó la ubicación. Sin clave
  /// foránea, como el resto de la tabla: borrar un lugar no debe borrar
  /// partidas.
  IntColumn get placeId => integer().nullable()();

  /// Jugadores detectados por Bluetooth al terminar, como lista JSON de
  /// `{code, name}`. Null si el jugador no activó "personas cercanas".
  TextColumn get nearby => text().nullable()();
}
