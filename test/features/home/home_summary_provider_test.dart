// drift y matcher exportan ambos `isNull`/`isNotNull`; en un test manda matcher.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/home/controller/home_controller.dart';
import 'package:memory_companion/features/home/model/home_summary.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// La prueba de que la Home es offline-first: este archivo no importa
/// Firebase por ningún lado, y aun así la cabecera se llena.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Espera a que el stream de SQLite propague un cambio hasta el resumen.
  Future<HomeSummary> waitForSummary(
    bool Function(HomeSummary summary) matches,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final summary = container.read(homeSummaryProvider);
      if (matches(summary)) return summary;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('el resumen nunca llegó al estado esperado');
  }

  test('el primer arranque deja la Home lista, sin cuenta y sin red',
      () async {
    final profile = await container.read(localPlayerProvider.future);
    final summary = container.read(homeSummaryProvider);

    expect(profile.cloudUid, isNull);
    expect(summary.isLoading, isFalse);
    expect(summary.level, 1);
    expect(summary.totalXp, 0);
    expect(summary.xpProgress, 0.0);
    expect(summary.xpRemaining, 1000);
    expect(summary.nextLevel, 2);
    expect(summary.hasStreak, isFalse);
  });

  test('el progreso guardado localmente llega a la cabecera', () async {
    final profile = await container.read(localPlayerProvider.future);

    await (db.update(db.playerProfiles)
          ..where((p) => p.localId.equals(profile.localId)))
        .write(
      const PlayerProfilesCompanion(
        displayName: Value('Jorge'),
        totalXp: Value(28350),
        currentStreak: Value(5),
      ),
    );

    final summary = await waitForSummary((s) => s.playerName == 'Jorge');

    expect(summary.totalXp, 28350);
    // Nivel y progreso se derivan; no hay ningún campo `level` que leer.
    expect(summary.level, 8);
    expect(summary.targetXp, 8000);
    expect(summary.xpRemaining, 7650);
    expect(summary.streakDays, 5);
    expect(summary.hasStreak, isTrue);
  });

  test('la barra se completa al cruzar el umbral del nivel', () async {
    final profile = await container.read(localPlayerProvider.future);

    await (db.update(db.playerProfiles)
          ..where((p) => p.localId.equals(profile.localId)))
        .write(const PlayerProfilesCompanion(totalXp: Value(999)));
    var summary = await waitForSummary((s) => s.totalXp == 999);
    expect(summary.level, 1);
    expect(summary.xpRemaining, 1);

    await (db.update(db.playerProfiles)
          ..where((p) => p.localId.equals(profile.localId)))
        .write(const PlayerProfilesCompanion(totalXp: Value(1000)));
    summary = await waitForSummary((s) => s.level == 2);
    expect(summary.xpProgress, 0.0, reason: 'estrena nivel, barra vacía');
    expect(summary.targetXp, 2000, reason: 'el nivel 2 pide 2.000 XP');
    expect(summary.xpRemaining, 2000);
  });
}
