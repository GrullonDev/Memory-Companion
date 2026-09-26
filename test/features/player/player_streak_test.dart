import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/player/model/player_streak.dart';

/// Los seis casos de la racha, sin base de datos de por medio.
void main() {
  DateTime day(int year, int month, int dayOfMonth, [int hour = 12]) {
    return DateTime(year, month, dayOfMonth, hour);
  }

  StreakUpdate play({
    String? lastPlayedDate,
    int currentStreak = 0,
    int longestStreak = 0,
    required DateTime now,
  }) {
    return advanceStreak(
      lastPlayedDate: lastPlayedDate,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      now: now,
    );
  }

  test('formatea la fecha local con ceros a la izquierda', () {
    expect(localDateKey(day(2026, 1, 5)), '2026-01-05');
    expect(localDateKey(day(2026, 12, 31)), '2026-12-31');
  });

  test('el primer día arranca la racha en 1', () {
    final result = play(now: day(2026, 8, 31));

    expect(result.currentStreak, 1);
    expect(result.longestStreak, 1);
    expect(result.lastPlayedDate, '2026-08-31');
    expect(result.changed, isTrue);
  });

  test('una fecha corrupta se trata como primer día', () {
    final result = play(lastPlayedDate: 'ayer', now: day(2026, 8, 31));

    expect(result.currentStreak, 1);
    expect(result.lastPlayedDate, '2026-08-31');
  });

  test('jugar otra vez el mismo día no sube la racha', () {
    final result = play(
      lastPlayedDate: '2026-08-31',
      currentStreak: 4,
      longestStreak: 9,
      now: day(2026, 8, 31, 23),
    );

    expect(result.currentStreak, 4);
    expect(result.longestStreak, 9);
    expect(result.changed, isFalse);
  });

  test('jugar al día siguiente suma uno', () {
    final result = play(
      lastPlayedDate: '2026-08-30',
      currentStreak: 4,
      longestStreak: 9,
      now: day(2026, 8, 31),
    );

    expect(result.currentStreak, 5);
    expect(result.longestStreak, 9, reason: 'aún no bate su récord');
    expect(result.lastPlayedDate, '2026-08-31');
  });

  test('superar el récord lo actualiza', () {
    final result = play(
      lastPlayedDate: '2026-08-30',
      currentStreak: 9,
      longestStreak: 9,
      now: day(2026, 8, 31),
    );

    expect(result.currentStreak, 10);
    expect(result.longestStreak, 10);
  });

  test('saltarse un día reinicia, pero conserva el récord', () {
    final result = play(
      lastPlayedDate: '2026-08-28',
      currentStreak: 12,
      longestStreak: 12,
      now: day(2026, 8, 31),
    );

    expect(result.currentStreak, 1, reason: 'vuelve a empezar');
    expect(result.longestStreak, 12, reason: 'lo conseguido no se borra');
  });

  test('varios días sin conexión no afectan: solo cuentan las fechas', () {
    // Jugó offline el día 30 y no sincronizó hasta el 31: la racha sigue.
    final result = play(
      lastPlayedDate: '2026-08-30',
      currentStreak: 3,
      now: day(2026, 8, 31),
    );

    expect(result.currentStreak, 4);
  });

  test('retrasar el reloj no infla la racha ni pierde la fecha', () {
    final result = play(
      lastPlayedDate: '2026-08-31',
      currentStreak: 7,
      longestStreak: 7,
      now: day(2026, 8, 25), // el jugador movió el reloj hacia atrás
    );

    expect(result.currentStreak, 7);
    expect(result.longestStreak, 7);
    expect(result.lastPlayedDate, '2026-08-31', reason: 'no retrocede');
    expect(result.changed, isFalse);
  });

  test('cruza fin de mes y fin de año sin romperse', () {
    expect(
      play(lastPlayedDate: '2026-08-31', currentStreak: 2, now: day(2026, 9, 1))
          .currentStreak,
      3,
    );
    expect(
      play(lastPlayedDate: '2026-12-31', currentStreak: 5, now: day(2027, 1, 1))
          .currentStreak,
      6,
    );
  });

  test('un año consecutivo suma 365 y no se descuadra', () {
    var streak = 0;
    var longest = 0;
    String? last;
    var date = day(2026, 1, 1);

    for (var i = 0; i < 365; i++) {
      final result = play(
        lastPlayedDate: last,
        currentStreak: streak,
        longestStreak: longest,
        now: date,
      );
      streak = result.currentStreak;
      longest = result.longestStreak;
      last = result.lastPlayedDate;
      date = DateTime(date.year, date.month, date.day + 1, 12);
    }

    // Si el cambio de horario de verano contaminara el cálculo, aquí
    // faltarían días.
    expect(streak, 365);
    expect(longest, 365);
  });
}
