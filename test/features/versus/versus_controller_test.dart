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
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/game_context/service/nearby_radio.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/cpu/cpu_opponent.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';
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
    for (var round = 0; round < 2; round++) {
      await duels.submitRound(
        duelId: duel.id,
        uid: 'alice',
        round: round,
        score: DuelScore(score: aliceWins ? 900 : 500, seconds: 30, moves: 8),
      );
      await duels.submitRound(
        duelId: duel.id,
        uid: rival,
        round: round,
        score: const DuelScore(score: 700, seconds: 30, moves: 8),
      );
    }
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

    expect(duel.game, DuelGame.memory);
    for (var round = 0; round < Duel.seriesRounds; round++) {
      await container
          .read(versusControllerProvider.notifier)
          .submitResult(
            duel,
            const DuelScore(score: 800, seconds: 45, moves: 9),
            round: round,
          );
    }
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

  test('el juego elegido llega al duelo, y la revancha lo repite', () async {
    await befriend('bob', 'Bob');
    final container = open();
    await waitFor(container, (s) => s.rival != null);
    container.read(selectedDuelGameProvider.notifier).select(DuelGame.words);

    final notifier = container.read(versusControllerProvider.notifier);
    final duel = await notifier.startDuel(languageCode: 'en');
    expect(duel!.game, DuelGame.words);

    container.read(selectedDuelGameProvider.notifier).select(DuelGame.digits);
    final rematch = await notifier.rematch(duel, languageCode: 'en');
    expect(rematch!.game, DuelGame.words);
    expect(rematch.opponentUid, 'bob');
    expect(rematch.id, isNot(duel.id));
  });

  group('salas', () {
    test('crear una sala la deja abierta y jugable por el anfitrión', () async {
      final container = open();
      await container.read(versusControllerProvider.future);

      final room = await container
          .read(versusControllerProvider.notifier)
          .createRoom(languageCode: 'es');
      expect(room, isNotNull);
      expect(room!.status, DuelStatus.open);
      expect(room.roomCode, hasLength(6));
      expect(room.opponentUid, isEmpty);

      final state = await waitFor(container, (s) => s.toPlay.isNotEmpty);
      expect(state.toPlay.single.id, room.id);
      expect(state.finished, isEmpty, reason: 'abierta no es terminada');
    });

    test('otro jugador entra con el código, sin ser amigos', () async {
      final host = open();
      await host.read(versusControllerProvider.future);
      final room = await host
          .read(versusControllerProvider.notifier)
          .createRoom(languageCode: 'es');

      final guest = open(uid: 'bob');
      await guest.read(versusControllerProvider.future);
      final result = await guest
          .read(versusControllerProvider.notifier)
          // Se acepta tal como se escribe a mano.
          .joinRoom(room!.roomCode!.toLowerCase());

      expect(result.status, JoinRoomStatus.joined);
      expect(result.duel?.id, room.id);
      expect(result.duel?.status, DuelStatus.pending);
      expect(result.duel?.members, ['alice', 'bob']);

      final state = await waitFor(guest, (s) => s.toPlay.isNotEmpty);
      expect(state.toPlay.single.id, room.id);

      // Ya no está abierta: nadie más puede entrar.
      final third = open(uid: 'carol');
      await third.read(versusControllerProvider.future);
      final late = await third
          .read(versusControllerProvider.notifier)
          .joinRoom(room.roomCode!);
      expect(late.status, JoinRoomStatus.notFound);
    });

    test('el anfitrión que escribe su código vuelve a su sala', () async {
      final container = open();
      await container.read(versusControllerProvider.future);
      final notifier = container.read(versusControllerProvider.notifier);
      final room = await notifier.createRoom(languageCode: 'es');

      final result = await notifier.joinRoom(room!.roomCode!);
      expect(result.status, JoinRoomStatus.joined);
      expect(result.duel?.status, DuelStatus.open);
    });

    test('códigos mal formados o sin sala', () async {
      final container = open();
      await container.read(versusControllerProvider.future);
      final notifier = container.read(versusControllerProvider.notifier);

      expect(
        (await notifier.joinRoom('12')).status,
        JoinRoomStatus.invalidCode,
      );
      expect(
        (await notifier.joinRoom('ZZZZZZ')).status,
        JoinRoomStatus.notFound,
      );
      expect(
        (await open(
          uid: null,
        ).read(versusControllerProvider.notifier).joinRoom('ZZZZZZ')).status,
        JoinRoomStatus.signedOut,
      );
    });
  });

  group('jugar (emparejamiento)', () {
    ProviderContainer openWith({
      String? uid = 'alice',
      bool online = true,
      Set<String>? heard = const {},
    }) {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          socialUidProvider.overrideWith((ref) async => uid),
          socialRepositoryProvider.overrideWithValue(social),
          duelRepositoryProvider.overrideWithValue(duels),
          duelRandomProvider.overrideWithValue(Random(7)),
          versusOnlineProvider.overrideWithValue(online),
          nearbyRadioProvider.overrideWithValue(_FakeRadio(heard)),
        ],
      );
      addTearDown(container.dispose);
      container.listen(versusControllerProvider, (_, _) {});
      return container;
    }

    Future<MatchResult> play(ProviderContainer container, PlayMode mode) async {
      await container.read(versusControllerProvider.future);
      return container
          .read(versusControllerProvider.notifier)
          .findMatch(mode: mode, languageCode: 'es');
    }

    test('en línea entra en la sala abierta de otro jugador', () async {
      final room = await duels.createRoom(
        hostUid: 'zoe',
        hostName: 'Zoe',
        roomCode: 'ABCDEF',
        seed: 1,
        categoryId: GameCategories.classic.id,
        languageCode: 'es',
      );
      final result = await play(openWith(), PlayMode.online);
      expect(result, isA<DuelMatch>());
      final duel = (result as DuelMatch).duel;
      expect(duel.id, room.id);
      expect(duel.opponentUid, 'alice');
    });

    test('en línea sin salas reta al amigo elegido', () async {
      await befriend('bob', 'Bob');
      final container = openWith();
      await waitFor(container, (s) => s.rival != null);
      final result = await play(container, PlayMode.online);
      expect((result as DuelMatch).duel.opponentUid, 'bob');
    });

    test('sin conexión busca por Bluetooth a un amigo cercano', () async {
      await befriend('bob', 'Bob');
      await befriend('carl', 'Carl');
      final container = openWith(
        online: false,
        heard: {FriendCode.fromUid('carl')},
      );
      await waitFor(container, (s) => s.rivals.length == 2);
      final result = await play(container, PlayMode.online);
      expect((result as DuelMatch).duel.opponentUid, 'carl');
    });

    test('sin nadie cerca ni en línea juega contra la máquina', () async {
      final result = await play(openWith(heard: null), PlayMode.nearby);
      expect(result, isA<CpuMatch>());
      expect((result as CpuMatch).level, CpuLevel.easy);
    });

    test('sin cuenta va directo a la máquina', () async {
      final result = await play(openWith(uid: null), PlayMode.online);
      expect(result, isA<CpuMatch>());
    });

    test('el nivel de la máquina sigue al del jugador', () {
      expect(VersusController.cpuLevelFor(1), CpuLevel.easy);
      expect(VersusController.cpuLevelFor(5), CpuLevel.normal);
      expect(VersusController.cpuLevelFor(10), CpuLevel.hard);
    });
  });
}

class _FakeRadio implements NearbyRadio {
  _FakeRadio(this.heard);

  final Set<String>? heard;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<Set<String>?> scan(Duration duration) async => heard;

  @override
  Future<void> startAdvertising(String friendCode) async {}

  @override
  Future<void> stopAdvertising() async {}
}
