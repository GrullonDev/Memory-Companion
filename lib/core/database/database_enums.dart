/// Estado de sincronización de una fila o de una operación en cola.
///
/// Se guarda como texto (`textEnum`) y no como índice entero a propósito:
/// insertar un valor nuevo en medio del enum no debe reinterpretar filas ya
/// escritas en el dispositivo de un jugador.
enum SyncStatus {
  /// Confirmado por el servidor.
  synced,

  /// Escrito en local, esperando su turno.
  pending,

  /// Enviándose ahora mismo.
  syncing,

  /// Falló y no se reintentará hasta el próximo evento de conectividad.
  failed,
}

/// Tipos de operación que el motor de sincronización sabe aplicar.
///
/// Cada valor se corresponde con una escritura idempotente contra Firestore.
/// Añadir un tipo obliga a añadir su manejador en el motor; retirarlo obliga
/// a una migración, porque puede haber operaciones de ese tipo esperando en
/// la cola del dispositivo de alguien.
enum SyncOperationType {
  /// Alta o actualización completa del perfil en la nube.
  upsertProfile,

  /// Partida ganada: incrementos de XP, monedas, victorias y movimientos.
  recordWin,

  /// XP suelto, sin victoria asociada.
  addXp,

  /// Monedas ganadas fuera de una partida.
  earnCoins,

  /// Monedas gastadas.
  spendCoins,

  /// Alta de una partida en el historial.
  createMatch,

  /// Nivel completado y su mejor puntuación.
  completeLevel,

  /// Reto diario completado.
  completeChallenge,

  /// Racha diaria.
  updateStreak,
}
