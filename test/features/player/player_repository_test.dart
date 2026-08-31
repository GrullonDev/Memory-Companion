// drift y matcher exportan ambos `isNull`/`isNotNull`; en un test manda matcher.
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

void main() {
  late AppDatabase db;
  late int idCounter;
  late DateTime now;

  PlayerRepository buildRepository() {
    return PlayerRepository(
      database: db,
      idGenerator: () => 'local-${++idCounter}',
      clock: () => now,
    );
  }

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    idCounter = 0;
    now = DateTime.fromMillisecondsSinceEpoch(1000);
  });

  tearDown(() async {
    await db.close();
  });

  test('antes del primer arranque no hay identidad', () async {
    expect(await buildRepository().readLocalProfile(), isNull);
  });

  test('el primer arranque crea un jugador local completo', () async {
    final profile = await buildRepository().ensureLocalProfile();

    expect(profile.localId, 'local-1');
    expect(profile.cloudUid, isNull, reason: 'nace sin cuenta');
    expect(profile.isLinkedToCloud, isFalse);
    expect(profile.hasPlayed, isFalse);
    expect(profile.totalXp, 0);
    expect(profile.totalCoins, 0);
    expect(profile.version, 0);
    expect(profile.createdAt, now);
  });

  test('llamarlo de nuevo devuelve la misma identidad, no una segunda',
      () async {
    final repository = buildRepository();

    final first = await repository.ensureLocalProfile();
    now = now.add(const Duration(days: 30));
    final second = await repository.ensureLocalProfile();

    expect(second.localId, first.localId);
    expect(idCounter, 1, reason: 'no se generó un UUID nuevo');
    expect(await db.select(db.playerProfiles).get(), hasLength(1));
  });

  test('dos arranques concurrentes no producen dos identidades', () async {
    final repository = buildRepository();

    final results = await Future.wait([
      repository.ensureLocalProfile(),
      repository.ensureLocalProfile(),
      repository.ensureLocalProfile(),
    ]);

    expect(results.map((p) => p.localId).toSet(), hasLength(1));
    expect(await db.select(db.playerProfiles).get(), hasLength(1));
  });

  test('vincular una cuenta conserva el localId y todo el progreso',
      () async {
    final repository = buildRepository();
    final local = await repository.ensureLocalProfile();

    // 30 días de juego sin cuenta.
    await (db.update(db.playerProfiles)
          ..where((p) => p.localId.equals(local.localId)))
        .write(
      const PlayerProfilesCompanion(
        totalXp: Value(8400),
        totalCoins: Value(1250),
        gamesWon: Value(42),
        currentStreak: Value(5),
        longestStreak: Value(11),
        lastPlayedDate: Value('2026-08-30'),
      ),
    );

    now = now.add(const Duration(days: 30));
    await repository.linkToCloud(
      localId: local.localId,
      cloudUid: 'firebase-uid-abc',
    );

    final linked = await repository.readLocalProfile();
    expect(linked, isNotNull);
    expect(linked!.localId, local.localId, reason: 'la identidad no cambia');
    expect(linked.cloudUid, 'firebase-uid-abc');
    expect(linked.isLinkedToCloud, isTrue);
    // Nada de esto se toca al vincular: no hay traspaso, hay vinculación.
    expect(linked.totalXp, 8400);
    expect(linked.totalCoins, 1250);
    expect(linked.gamesWon, 42);
    expect(linked.currentStreak, 5);
    expect(linked.longestStreak, 11);
    expect(linked.lastPlayedDate, '2026-08-30');
    expect(await db.select(db.playerProfiles).get(), hasLength(1));
  });

  test('cambiar identidad sube la versión para poder resolver conflictos',
      () async {
    final repository = buildRepository();
    final profile = await repository.ensureLocalProfile();

    await repository.updateIdentity(
      localId: profile.localId,
      displayName: 'Jorge',
    );
    await repository.updateIdentity(localId: profile.localId, avatarSeed: 7);

    final updated = await repository.readLocalProfile();
    expect(updated!.displayName, 'Jorge');
    expect(updated.avatarSeed, 7);
    expect(updated.version, 2);
  });

  test('una actualización vacía no gasta una versión', () async {
    final repository = buildRepository();
    final profile = await repository.ensureLocalProfile();

    await repository.updateIdentity(localId: profile.localId);

    expect((await repository.readLocalProfile())!.version, 0);
  });

  test('watchLocalProfile emite el estado inicial y cada cambio', () async {
    final repository = buildRepository();
    final profile = await repository.ensureLocalProfile();

    final emissions = repository.watchLocalProfile();

    expectLater(
      emissions.map((p) => p?.displayName),
      emitsInOrder(<String>['', 'Jorge']),
    );

    await repository.updateIdentity(
      localId: profile.localId,
      displayName: 'Jorge',
    );
  });
}
