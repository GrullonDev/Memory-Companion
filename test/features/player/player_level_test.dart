import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/player/model/player_level.dart';

void main() {
  group('límites de nivel', () {
    test('el XP acumulado de arranque sigue la curva acumulada', () {
      expect(totalXpAtLevelStart(1), 0);
      expect(totalXpAtLevelStart(2), 1000);
      expect(totalXpAtLevelStart(3), 3000);
      expect(totalXpAtLevelStart(4), 6000);
      expect(totalXpAtLevelStart(10), 45000);
    });

    test('un jugador nuevo está en el nivel 1', () {
      expect(levelFromTotalXp(0), 1);
      expect(levelFromTotalXp(-500), 1, reason: 'defensivo, no debería pasar');
      expect(levelFromTotalXp(999), 1);
    });

    test('el límite exacto estrena el nivel, no cierra el anterior', () {
      // Es donde la raíz en coma flotante se equivoca si no se corrige.
      expect(levelFromTotalXp(1000), 2);
      expect(levelFromTotalXp(3000), 3);
      expect(levelFromTotalXp(6000), 4);
      expect(levelFromTotalXp(45000), 10);
    });

    test('un XP por debajo del límite sigue en el nivel anterior', () {
      expect(levelFromTotalXp(999), 1);
      expect(levelFromTotalXp(2999), 2);
      expect(levelFromTotalXp(44999), 9);
    });

    test('el nivel nunca baja al subir el XP', () {
      var previous = 1;
      for (var xp = 0; xp <= 200000; xp += 137) {
        final level = levelFromTotalXp(xp);
        expect(level, greaterThanOrEqualTo(previous));
        previous = level;
      }
    });

    test('nivel y arranque de nivel son consistentes en todo el rango', () {
      for (var level = 1; level <= 60; level++) {
        final start = totalXpAtLevelStart(level);
        expect(levelFromTotalXp(start), level);
        expect(levelFromTotalXp(start - 1), level == 1 ? 1 : level - 1);
      }
    });
  });

  group('progreso dentro del nivel', () {
    test('en el arranque de un nivel el progreso es cero', () {
      expect(xpIntoLevel(3000), 0);
      expect(levelProgress(3000), 0.0);
      expect(xpToNextLevel(3000), 3000, reason: 'el nivel 3 pide 3.000 XP');
    });

    test('a mitad de nivel el progreso es la mitad', () {
      // Nivel 3 arranca en 3.000 y pide 3.000 más.
      expect(levelFromTotalXp(4500), 3);
      expect(xpIntoLevel(4500), 1500);
      expect(levelProgress(4500), 0.5);
      expect(xpToNextLevel(4500), 1500);
    });

    test('el progreso siempre cae entre 0 y 1', () {
      for (var xp = 0; xp <= 100000; xp += 311) {
        expect(levelProgress(xp), inInclusiveRange(0.0, 1.0));
        expect(xpToNextLevel(xp), greaterThan(0));
        expect(xpIntoLevel(xp), greaterThanOrEqualTo(0));
      }
    });
  });

  group('migración desde el modelo heredado', () {
    test('un jugador coherente conserva su nivel exacto', () {
      // Nivel 8 con 350 XP dentro: 500·7·8 = 28.000, más 350.
      final total = migratedTotalXp(legacyLevel: 8, legacyCurrentXp: 350);
      expect(total, 28350);
      expect(levelFromTotalXp(total), 8);
      expect(xpIntoLevel(total), 350);
    });

    test('un jugador nuevo migra a cero', () {
      expect(migratedTotalXp(legacyLevel: 1, legacyCurrentXp: 0), 0);
      expect(levelFromTotalXp(0), 1);
    });

    test('la víctima del bug recupera el nivel que le correspondía', () {
      // El bug: `level` nunca se escribía, así que el jugador se quedaba en 1
      // mientras `currentXp` crecía sin límite.
      final total = migratedTotalXp(legacyLevel: 1, legacyCurrentXp: 45000);
      expect(total, 45000);
      expect(levelFromTotalXp(total), 10);
    });

    test('tolera datos corruptos sin romperse', () {
      expect(migratedTotalXp(legacyLevel: 0, legacyCurrentXp: 0), 0);
      expect(migratedTotalXp(legacyLevel: -3, legacyCurrentXp: -100), 0);
    });

    test('migrar no pierde XP: el total nunca baja del que ya tenía dentro',
        () {
      for (var level = 1; level <= 30; level++) {
        for (final within in [0, 1, 499, 1000]) {
          final total =
              migratedTotalXp(legacyLevel: level, legacyCurrentXp: within);
          expect(total, greaterThanOrEqualTo(within));
          expect(levelFromTotalXp(total), greaterThanOrEqualTo(level));
        }
      }
    });
  });
}
