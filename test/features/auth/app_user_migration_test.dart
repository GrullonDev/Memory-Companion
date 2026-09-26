import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/auth/model/user.dart';

/// La migración vive en el punto de lectura: un documento sin `totalXp` es un
/// documento del modelo antiguo. Estos tests protegen el progreso de quien ya
/// estaba jugando antes del cambio.
void main() {
  Map<String, dynamic> legacyDoc({required int level, required int currentXp}) {
    return <String, dynamic>{
      'email': 'jugador@example.com',
      'displayName': 'Jorge',
      'level': level,
      'currentXp': currentXp,
      'totalCoins': 1250,
      'gamesWon': 42,
      'bestStreak': 11,
    };
  }

  test('un documento heredado conserva nivel y progreso exactos', () {
    final user = AppUser.fromFirestore(
      legacyDoc(level: 8, currentXp: 350),
      'uid-1',
    );

    expect(user.totalXp, 28350, reason: '500·7·8 = 28.000, más 350');
    expect(user.level, 8, reason: 'el jugador no nota ningún salto');
    expect(user.xpIntoCurrentLevel, 350);
    expect(user.xpNeededForCurrentLevel, 8000);
  });

  test('la víctima del bug recupera el nivel que le correspondía', () {
    // `level` nunca se escribía: el jugador acumulaba XP atrapado en Nivel 1.
    final user = AppUser.fromFirestore(
      legacyDoc(level: 1, currentXp: 45000),
      'uid-2',
    );

    expect(user.totalXp, 45000);
    expect(user.level, 10);
  });

  test('un documento ya migrado ignora los campos heredados', () {
    final doc = legacyDoc(level: 8, currentXp: 350)..['totalXp'] = 99000;

    final user = AppUser.fromFirestore(doc, 'uid-3');

    expect(user.totalXp, 99000, reason: 'gana el campo nuevo');
    expect(user.level, 14);
  });

  test('un documento sin datos de progreso arranca en cero', () {
    final user = AppUser.fromFirestore(
      <String, dynamic>{'email': 'nuevo@example.com'},
      'uid-4',
    );

    expect(user.totalXp, 0);
    expect(user.level, 1);
    expect(user.totalCoins, 0);
  });

  test('el resto de los campos sobrevive a la migración', () {
    final user = AppUser.fromFirestore(
      legacyDoc(level: 8, currentXp: 350),
      'uid-5',
    );

    expect(user.displayName, 'Jorge');
    expect(user.totalCoins, 1250);
    expect(user.gamesWon, 42);
    expect(user.bestStreak, 11);
  });

  test('al escribir no viaja ningún derivado', () {
    final user = AppUser.fromFirestore(
      legacyDoc(level: 8, currentXp: 350),
      'uid-6',
    );

    final written = user.toFirestore();

    expect(written['totalXp'], 28350);
    // Un derivado que viaja es un conflicto esperando a ocurrir.
    expect(written.containsKey('level'), isFalse);
    expect(written.containsKey('currentXp'), isFalse);
  });
}
