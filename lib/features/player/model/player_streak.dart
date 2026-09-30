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
    this.freezesUsed = 0,
    this.bonusCoins = 0,
  });

  final int currentStreak;
  final int longestStreak;

  /// `'YYYY-MM-DD'` del último día jugado.
  final String lastPlayedDate;

  /// Si esta llamada movió algo. Falso cuando ya se había jugado hoy.
  final bool changed;

  /// Protectores de racha gastados para tapar días sin jugar.
  final int freezesUsed;

  /// Monedas pagadas por este día de racha ([streakDayCoins]). Las fija el
  /// repositorio al cobrarlas; la función pura siempre devuelve 0.
  final int bonusCoins;

  /// Si esta llamada estrenó un día de juego (y no solo corrigió datos).
  bool isNewDay(String? previousDate) => changed && lastPlayedDate != previousDate;

  StreakUpdate withBonus(int coins) => StreakUpdate(
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    lastPlayedDate: lastPlayedDate,
    changed: changed,
    freezesUsed: freezesUsed,
    bonusCoins: coins,
  );

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
///  * **Día perdido** — han pasado dos días o más: vuelve a 1, sin drama…
///    salvo que haya [availableFreezes] para cubrir cada día perdido: entonces
///    se gastan y la racha sigue como si no hubiera faltado.
///  * **Varios días sin conexión** — da igual: solo cuentan las fechas.
///  * **Reloj hacia atrás** — la última fecha está en el futuro: no se toca
///    nada, ni siquiera [lastPlayedDate]. Retroceder el reloj no puede
///    inflar la racha, y adelantarlo tampoco la regala.
StreakUpdate advanceStreak({
  required String? lastPlayedDate,
  required int currentStreak,
  required int longestStreak,
  required DateTime now,
  int availableFreezes = 0,
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
      longestStreak: longestStreak < currentStreak
          ? currentStreak
          : longestStreak,
      lastPlayedDate: todayKey,
      changed: currentStreak < 1,
    );
  }

  final missed = gap - 1;
  final frozen = missed > 0 && currentStreak > 0 && missed <= availableFreezes;
  final next = gap == 1 || frozen ? currentStreak + 1 : 1;

  return StreakUpdate(
    currentStreak: next,
    longestStreak: longestStreak < next ? next : longestStreak,
    lastPlayedDate: todayKey,
    changed: true,
    freezesUsed: frozen ? missed : 0,
  );
}

/// Días de racha que dan un premio extra. Tras el último, uno cada 50 días:
/// la racha no tiene techo y los premios tampoco.
const streakMilestones = [3, 7, 14, 30, 60, 100];

/// El siguiente hito por encima de [streak].
int nextStreakMilestone(int streak) {
  for (final milestone in streakMilestones) {
    if (milestone > streak) return milestone;
  }
  return (streak ~/ 50 + 1) * 50;
}

bool isStreakMilestone(int streak) =>
    streakMilestones.contains(streak) ||
    (streak > streakMilestones.last && streak % 50 == 0);

/// Monedas por jugar el día [streak] de una racha: 10 por día seguido, hasta
/// 70 a partir de la semana, más un premio grande en cada hito. Es lo que
/// hace que volver mañana valga más que volver pasado mañana.
int streakDayCoins(int streak) {
  if (streak < 1) return 0;
  final daily = 10 * (streak > 7 ? 7 : streak);
  final milestone = isStreakMilestone(streak) ? 20 * streak : 0;
  return daily + milestone;
}

/// Cómo está la racha vista desde un momento dado, sin tocar nada.
enum StreakStatus {
  /// Nunca ha jugado, o la racha se rompió y no hay protectores que la
  /// cubran.
  none,

  /// Ya jugó hoy.
  safe,

  /// Jugó ayer, o los protectores cubren los días perdidos: si juega hoy,
  /// la racha sigue.
  atRisk,
}

/// La racha que verá el jugador en [now]: la guardada, o 0 si ya se rompió.
///
/// Solo para pintar: la racha guardada no se corrige hasta la próxima
/// partida, que es cuando [advanceStreak] decide de verdad.
({StreakStatus status, int days}) streakStatusAt({
  required String? lastPlayedDate,
  required int currentStreak,
  required DateTime now,
  int availableFreezes = 0,
}) {
  final last = _dayNumberOf(lastPlayedDate);
  if (last == null || currentStreak < 1) {
    return (status: StreakStatus.none, days: 0);
  }
  final gap = _dayNumber(now.year, now.month, now.day) - last;
  if (gap <= 0) return (status: StreakStatus.safe, days: currentStreak);
  if (gap - 1 <= availableFreezes) {
    return (status: StreakStatus.atRisk, days: currentStreak);
  }
  return (status: StreakStatus.none, days: 0);
}
