import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/lives/model/lives_recovery.dart';

void main() {
  const maxLives = 5;
  const refill = Duration(minutes: 20);
  final start = DateTime(2026, 8, 31, 10);

  LivesSnapshot recover({
    required int stored,
    required Duration elapsed,
  }) {
    return recoverLives(
      storedCurrent: stored,
      storedLastRefillAt: start,
      now: start.add(elapsed),
      maxLives: maxLives,
      refillInterval: refill,
    );
  }

  test('con todas las vidas no hay cuenta atrás', () {
    final snapshot = recover(stored: maxLives, elapsed: Duration.zero);

    expect(snapshot.current, maxLives);
    expect(snapshot.secondsUntilNextLife, 0);
  });

  test('antes del primer intervalo no se recupera nada', () {
    final snapshot = recover(stored: 2, elapsed: const Duration(minutes: 19));

    expect(snapshot.current, 2);
    expect(snapshot.secondsUntilNextLife, 60);
  });

  test('cumplido el intervalo se recupera una vida', () {
    final snapshot = recover(stored: 2, elapsed: const Duration(minutes: 20));

    expect(snapshot.current, 3);
    expect(snapshot.secondsUntilNextLife, refill.inSeconds);
  });

  test('el tiempo ya cumplido no se tira al recuperar', () {
    // 25 minutos: una vida entera y 5 minutos de la siguiente.
    final snapshot = recover(stored: 2, elapsed: const Duration(minutes: 25));

    expect(snapshot.current, 3);
    expect(
      snapshot.secondsUntilNextLife,
      const Duration(minutes: 15).inSeconds,
      reason: 'los 5 minutos cumplidos se conservan',
    );
  });

  test('cerrar la app horas no da más del máximo', () {
    final snapshot = recover(stored: 0, elapsed: const Duration(hours: 12));

    expect(snapshot.current, maxLives);
    expect(snapshot.secondsUntilNextLife, 0);
  });

  test('justo al llenarse el contador se apaga', () {
    final snapshot = recover(stored: 4, elapsed: const Duration(minutes: 20));

    expect(snapshot.current, maxLives);
    expect(snapshot.secondsUntilNextLife, 0);
  });

  test('atrasar el reloj no regala vidas ni rompe el cálculo', () {
    final snapshot = recoverLives(
      storedCurrent: 1,
      storedLastRefillAt: start,
      now: start.subtract(const Duration(hours: 3)),
      maxLives: maxLives,
      refillInterval: refill,
    );

    expect(snapshot.current, 1);
    expect(snapshot.lastRefillAt, start, reason: 'no se mueve el ancla');
  });

  test('recuperar por tramos equivale a recuperar de una vez', () {
    // Tres saltos de 20 minutos desde 0 vidas.
    var current = 0;
    var anchor = start;
    for (var i = 1; i <= 3; i++) {
      final step = recoverLives(
        storedCurrent: current,
        storedLastRefillAt: anchor,
        now: start.add(Duration(minutes: 20 * i)),
        maxLives: maxLives,
        refillInterval: refill,
      );
      current = step.current;
      anchor = step.lastRefillAt;
    }

    expect(current, 3);
    expect(recover(stored: 0, elapsed: const Duration(minutes: 60)).current, 3);
  });
}
