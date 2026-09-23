/// La racha diaria: días consecutivos en los que el jugador ha jugado.
///
/// Estaba en el modelo, se pintaba en la Home y en el Perfil, y **nadie la
/// escribía nunca**: era siempre 0. Aquí vive la lógica completa, como
/// función pura, para poder probar los seis casos sin base de datos.
///
/// Todo se resuelve con fechas **locales en texto** (`'YYYY-MM-DD'`) y no con
/// marcas de tiempo del servidor: la racha tiene que funcionar en avión, y
/// tiene que seguir teniendo sentido si el jugador cruza un huso horario.
library;

/// Resultado de registrar que el jugador ha jugado hoy.
class StreakUpdate {
  const StreakUpdate({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastPlayedDate,
    required this.changed,
  });

  final int currentStreak;
  final int longestStreak;

  /// `'YYYY-MM-DD'` del último día jugado.
  final String lastPlayedDate;

  /// Si esta llamada movió algo. Falso cuando ya se había jugado hoy.
  final bool changed;

  @override
  String toString() =>
      'StreakUpdate($currentStreak, mejor: $longestStreak, $lastPlayedDate)';
}

/// Formatea una fecha como `'YYYY-MM-DD'` usando sus componentes **locales**.
String localDateKey(DateTime dateTime) {
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  return '${dateTime.year}-$month-$day';
}

/// Número de día absoluto para una fecha civil.
///
/// Se construye en UTC a partir de los componentes **locales** a propósito.
/// Restar dos `DateTime` locales daría 23 o 25 horas en los cambios de
/// horario de verano, y `inDays` redondearía a 0 o a 2: la racha de un
/// jugador se rompería dos veces al año sin que él hubiera fallado un día.
int _dayNumber(int year, int month, int day) {
  return DateTime.utc(year, month, day).millisecondsSinceEpoch ~/
      Duration.millisecondsPerDay;
}

int? _dayNumberOf(String? dateKey) {
  if (dateKey == null || dateKey.isEmpty) return null;
  final parsed = DateTime.tryParse(dateKey);
  if (parsed == null) return null;
  return _dayNumber(parsed.year, parsed.month, parsed.day);
}

/// Registra que el jugador ha jugado en [now] y devuelve la racha resultante.
///
/// Los seis casos:
///
///  * **Primer día** — nunca había jugado: la racha arranca en 1.
///  * **Mismo día** — ya jugó hoy: no se mueve nada.
///  * **Día consecutivo** — jugó ayer: suma uno.
///  * **Día perdido** — han pasado dos días o más: vuelve a 1, sin drama.
///  * **Varios días sin conexión** — da igual: solo cuentan las fechas.
///  * **Reloj hacia atrás** — la última fecha está en el futuro: no se toca
///    nada, ni siquiera [lastPlayedDate]. Retroceder el reloj no puede
///    inflar la racha, y adelantarlo tampoco la regala.
StreakUpdate advanceStreak({
  required String? lastPlayedDate,
  required int currentStreak,
  required int longestStreak,
  required DateTime now,
}) {
  final todayKey = localDateKey(now);
  final today = _dayNumber(now.year, now.month, now.day);
  final last = _dayNumberOf(lastPlayedDate);

  // Sin fecha previa —o con una corrupta— se empieza de cero.
  if (last == null) {
    return StreakUpdate(
      currentStreak: 1,
      longestStreak: longestStreak < 1 ? 1 : longestStreak,
      lastPlayedDate: todayKey,
      changed: true,
    );
  }

  final gap = today - last;

  // La última partida está en el futuro: el reloj se movió. No se premia.
  if (gap < 0) {
    return StreakUpdate(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastPlayedDate: lastPlayedDate!,
      changed: false,
    );
  }

  // Ya jugó hoy: la racha no sube dos veces en un día.
  if (gap == 0) {
    return StreakUpdate(
      currentStreak: currentStreak < 1 ? 1 : currentStreak,
      longestStreak: longestStreak < currentStreak ? currentStreak : longestStreak,
      lastPlayedDate: todayKey,
      changed: currentStreak < 1,
    );
  }

  final next = gap == 1 ? currentStreak + 1 : 1;

  return StreakUpdate(
    currentStreak: next,
    longestStreak: longestStreak < next ? next : longestStreak,
    lastPlayedDate: todayKey,
    changed: true,
  );
}
