import 'dart:math';

import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/friends/repository/social_repository.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/repository/duel_repository.dart';

void main() {
  late AppDatabase db;
  late SocialRepository social;
  late DuelRepository duels;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final firestore = FakeFirebaseFirestore();
    social = SocialRepository(firestore: firestore);
    duels = DuelRepository(firestore: firestore);
  });
  tearDown(() => db.close());

  ProviderContainer open({String? uid = 'alice'}) {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        socialUidProvider.overrideWith((ref) async => uid),
        socialRepositoryProvider.overrideWithValue(social),
        duelRepositoryProvider.overrideWithValue(duels),
        duelRandomProvider.overrideWithValue(Random(7)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(versusControllerProvider, (_, _) {});
    return container;
  }

  Future<void> befriend(String other, String name, {int xp = 1500}) async {
    await social.publishProfile(
      uid: other,
      displayName: name,
      avatarSeed: 0,
      level: 2,
      totalXp: xp,
      friendCode: FriendCode.fromUid(other),
    );
    await social.sendRequest(from: 'alice', to: other);
    await social.sendRequest(from: other, to: 'alice');
  }

  Future<VersusState> waitFor(
    ProviderContainer container,
    bool Function(VersusState state) condition,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final state = container.read(versusControllerProvider).value;
      if (state != null && condition(state)) return state;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('el estado de Versus nunca cumplió la condición');
  }

  Future<Duel> finishedDuel(String rival, {required bool aliceWins}) async {
    final duel = await duels.create(
      challengerUid: 'alice',
      opponentUid: rival,
      friendshipId: 'x',
      seed: 1,
      categoryId: GameCategories.classic.id,
      languageCode: 'es',
    );
    await duels.submitResult(
      duelId: duel.id,
      uid: 'alice',
      score: DuelScore(score: aliceWins ? 900 : 500, seconds: 30, moves: 8),
    );
    await duels.submitResult(
      duelId: duel.id,
      uid: rival,
      score: const DuelScore(score: 700, seconds: 30, moves: 8),
    );
    return duel;
  }

  test('sin cuenta se ve la propia carta, pero no hay rival', () async {
    final state = await open(uid: null).read(versusControllerProvider.future);
    expect(state.isSignedIn, isFalse);
    expect(state.me.level, 1);
    expect(state.rivalCard, isNull);
  });

  test('sin amigos no hay rival ni duelo que empezar', () async {
    final container = open();
    final state = await container.read(versusControllerProvider.future);
    expect(state.isSignedIn, isTrue);
    expect(state.rival, isNull);
    expect(
      await container
          .read(versusControllerProvider.notifier)
          .startDuel(languageCode: 'es'),
      isNull,
    );
  });

  test('el rival es un amigo real, y se puede elegir otro', () async {
    await befriend('bob', 'Bob', xp: 3000);
    await befriend('carol', 'Carol');
    final container = open();
    final state = await container.read(versusControllerProvider.future);

    expect(state.rivals, hasLength(2));
    expect(state.rivalCard?.name, state.rival?.name);

    container.read(versusControllerProvider.notifier).selectRival('bob');
    final picked = await waitFor(container, (s) => s.rival?.uid == 'bob');
    expect(picked.rivalCard?.name, 'Bob');
    expect(picked.rivalCard?.totalXp, 3000);
    expect(picked.rivalCard?.level, 3, reason: 'el nivel sale del XP');
  });

  test('empezar un duelo lo crea contra el rival elegido', () async {
    await befriend('bob', 'Bob');
    final container = open();
    await container.read(versusControllerProvider.future);

    final duel = await container
        .read(versusControllerProvider.notifier)
        .startDuel(languageCode: 'en');
    expect(duel, isNotNull);
    expect(duel!.challengerUid, 'alice');
    expect(duel.opponentUid, 'bob');
    expect(duel.friendshipId, 'alice_bob');
    expect(duel.languageCode, 'en');

    // Aún no ha jugado nadie: es el turno de Alice.
    final state = await waitFor(container, (s) => s.toPlay.isNotEmpty);
    expect(state.toPlay.single.id, duel.id);
    expect(state.toPlay.single.isInvitationFor('alice'), isFalse);

    await container
        .read(versusControllerProvider.notifier)
        .submitResult(duel, const DuelScore(score: 800, seconds: 45, moves: 9));
    final waiting = await waitFor(container, (s) => s.waiting.isNotEmpty);
    expect(waiting.toPlay, isEmpty);
    expect(waiting.nameOf('bob'), 'Bob');
  });

  test('un reto recibido se puede rechazar', () async {
    await befriend('bob', 'Bob');
    await duels.create(
      challengerUid: 'bob',
      opponentUid: 'alice',
      friendshipId: 'alice_bob',
      seed: 3,
      categoryId: GameCategories.classic.id,
      languageCode: 'es',
    );
    final container = open();
    final state = await waitFor(container, (s) => s.toPlay.isNotEmpty);
    expect(state.toPlay.single.isInvitationFor('alice'), isTrue);

    await container
        .read(versusControllerProvider.notifier)
        .decline(state.toPlay.single);
    final after = await waitFor(container, (s) => s.finished.isNotEmpty);
    expect(after.toPlay, isEmpty);
    expect(after.finished.single.status, DuelStatus.declined);
  });

  test('la forma refleja los duelos terminados', () async {
    await befriend('bob', 'Bob');
    await finishedDuel('bob', aliceWins: true);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await finishedDuel('bob', aliceWins: false);

    final state = await waitFor(open(), (s) => s.finished.length == 2);
    // Del más viejo al más nuevo: ganó y luego perdió.
    expect(state.me.formWins, [true, false]);
    expect(state.rivalCard?.formWins, [false, true]);
  });
}
