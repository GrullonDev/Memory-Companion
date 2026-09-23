import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';
import 'package:memory_companion/features/settings/repository/display_settings_repository.dart';

/// Deja correr el bucle de eventos hasta que [done] se cumpla.
Future<void> pumpEventQueueUntil(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AppDatabase db;
  late DisplaySettingsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DisplaySettingsRepository(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  test('sin fila guardada se sirven los valores por defecto', () async {
    final preferences = await repository.read();

    expect(preferences, DisplayPreferences.defaults);
    expect(preferences.visualProfile, VisualProfile.vibrant);
    expect(preferences.timedMatches, isTrue);
  });

  test('elegir el perfil accesible apaga el temporizador', () async {
    await repository.setVisualProfile(VisualProfile.accessible);

    final preferences = await repository.read();
    expect(preferences.visualProfile, VisualProfile.accessible);
    expect(preferences.timedMatches, isFalse);
  });

  test(
    'el jugador puede volver a activar el reloj en modo accesible',
    () async {
      await repository.setVisualProfile(VisualProfile.accessible);
      await repository.setTimedMatches(true);

      final preferences = await repository.read();
      expect(
        preferences.visualProfile,
        VisualProfile.accessible,
        reason: 'cambiar el reloj no debe tocar el perfil',
      );
      expect(preferences.timedMatches, isTrue);
    },
  );

  test('cambiar el reloj antes de elegir perfil no altera el perfil', () async {
    await repository.setTimedMatches(false);

    final preferences = await repository.read();
    expect(preferences.visualProfile, VisualProfile.vibrant);
    expect(preferences.timedMatches, isFalse);
  });

  test('volver al perfil dinámico restaura su cuenta atrás', () async {
    await repository.setVisualProfile(VisualProfile.accessible);
    await repository.setVisualProfile(VisualProfile.vibrant);

    expect((await repository.read()).timedMatches, isTrue);
  });

  test('la tabla nunca tiene más de una fila', () async {
    await repository.setVisualProfile(VisualProfile.accessible);
    await repository.setTimedMatches(true);
    await repository.setVisualProfile(VisualProfile.vibrant);

    expect(await db.select(db.displaySettings).get(), hasLength(1));
  });

  test('watch emite el valor inicial y cada cambio', () async {
    final emitted = <VisualProfile>[];
    final subscription = repository.watch().listen(
      (p) => emitted.add(p.visualProfile),
    );

    // Se escribe solo después de la primera emisión: si no, la escritura
    // puede ganarle a la consulta inicial y el valor por defecto no llega
    // a verse nunca.
    await pumpEventQueueUntil(() => emitted.isNotEmpty);
    await repository.setVisualProfile(VisualProfile.accessible);
    await pumpEventQueueUntil(() => emitted.length == 2);
    await subscription.cancel();

    expect(emitted, [VisualProfile.vibrant, VisualProfile.accessible]);
  });

  test('el modo accesible deja las cartas fallidas visibles más tiempo', () {
    const vibrant = DisplayPreferences();
    const accessible = DisplayPreferences(
      visualProfile: VisualProfile.accessible,
    );

    expect(vibrant.mismatchRevealFloor, Duration.zero);
    expect(
      accessible.mismatchRevealFloor,
      greaterThanOrEqualTo(const Duration(seconds: 1)),
    );
  });
}
