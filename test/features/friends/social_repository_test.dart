import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/friends/model/friendship.dart';
import 'package:memory_companion/features/friends/model/public_player.dart';
import 'package:memory_companion/features/friends/repository/social_repository.dart';

void main() {
  group('FriendCode', () {
    test('es estable, de 6 caracteres y sin letras confusas', () {
      final code = FriendCode.fromUid('alice-uid');
      expect(code, FriendCode.fromUid('alice-uid'));
      expect(code, hasLength(FriendCode.length));
      expect(code, isNot(matches(RegExp('[01ILO]'))));
      expect(FriendCode.fromUid('bob-uid'), isNot(code));
    });

    test('normaliza lo que escribe el jugador', () {
      final code = FriendCode.fromUid('alice-uid');
      expect(FriendCode.normalize(code.toLowerCase()), code);
      expect(
        FriendCode.normalize(' ${code.substring(0, 3)}-${code.substring(3)} '),
        code,
      );
      expect(FriendCode.normalize('ABC'), isNull);
      expect(FriendCode.normalize('ABCDE0'), isNull, reason: '0 no existe');
    });
  });

  group('Friendship', () {
    test('una pareja tiene un solo id, sin importar quién pide', () {
      expect(Friendship.idFor('b', 'a'), Friendship.idFor('a', 'b'));
      expect(Friendship.membersOf('b', 'a'), ['a', 'b']);
    });
  });

  group('PublicPlayer', () {
    final now = DateTime(2026, 9, 24, 12);

    test('en línea si se le vio hace poco; en partida si está jugando', () {
      PublicPlayer seen(Duration ago, {bool playing = false}) => PublicPlayer(
        uid: 'x',
        displayName: 'X',
        lastSeenAt: now.subtract(ago),
        playing: playing,
      );

      expect(
        seen(const Duration(minutes: 2)).statusAt(now),
        FriendStatus.online,
      );
      expect(
        seen(const Duration(minutes: 2), playing: true).statusAt(now),
        FriendStatus.inGame,
      );
      expect(
        seen(const Duration(hours: 1), playing: true).statusAt(now),
        FriendStatus.offline,
        reason: 'un "jugando" viejo es de una sesión que se cerró',
      );
      expect(
        const PublicPlayer(uid: 'x', displayName: 'X').statusAt(now),
        FriendStatus.offline,
      );
    });
  });

  group('SocialRepository', () {
    late FakeFirebaseFirestore firestore;
    late SocialRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = SocialRepository(firestore: firestore);
    });

    Future<void> publish(String uid, String name) => repository.publishProfile(
      uid: uid,
      displayName: name,
      avatarSeed: 1,
      level: 3,
      totalXp: 3500,
      friendCode: FriendCode.fromUid(uid),
    );

    test('se encuentra a un jugador por su código', () async {
      await publish('bob', 'Bob');

      final found = await repository.findByCode(FriendCode.fromUid('bob'));
      expect(found?.uid, 'bob');
      expect(found?.displayName, 'Bob');
      expect(found?.totalXp, 3500);
      expect(found?.lastSeenAt, isNotNull);

      expect(await repository.findByCode('ZZZZZZ'), isNull);
    });

    test('solicitud, repetición y aceptación', () async {
      expect(
        await repository.sendRequest(from: 'alice', to: 'bob'),
        FriendRequestOutcome.sent,
      );
      expect(
        await repository.sendRequest(from: 'alice', to: 'bob'),
        FriendRequestOutcome.alreadyPending,
      );

      final pending = await repository.watchFriendships('bob').first;
      expect(pending.single.isIncomingFor('bob'), isTrue);
      expect(pending.single.isIncomingFor('alice'), isFalse);

      // Bob pide de vuelta: eso acepta la solicitud de Alice.
      expect(
        await repository.sendRequest(from: 'bob', to: 'alice'),
        FriendRequestOutcome.accepted,
      );
      expect(
        await repository.sendRequest(from: 'alice', to: 'bob'),
        FriendRequestOutcome.alreadyFriends,
      );
      final accepted = await repository.watchFriendships('alice').first;
      expect(accepted.single.isAccepted, isTrue);
      expect(accepted.single.otherOf('alice'), 'bob');
    });

    test('aceptar y eliminar', () async {
      await repository.sendRequest(from: 'alice', to: 'bob');
      final id = Friendship.idFor('alice', 'bob');

      await repository.accept(id);
      expect(
        (await repository.watchFriendships('bob').first).single.isAccepted,
        isTrue,
      );

      await repository.remove(id);
      expect(await repository.watchFriendships('alice').first, isEmpty);
    });

    test('los perfiles públicos se leen en bloque', () async {
      await publish('bob', 'Bob');
      await publish('carol', 'Carol');

      final players = await repository.watchPlayers([
        'bob',
        'carol',
        'nadie',
      ]).first;
      expect(players.keys, unorderedEquals(['bob', 'carol']));
      expect(await repository.watchPlayers(const []).first, isEmpty);
    });

    test('"jugando" se publica sin borrar el resto del perfil', () async {
      await publish('bob', 'Bob');
      await repository.setPlaying('bob', playing: true);

      final bob = await repository.findByCode(FriendCode.fromUid('bob'));
      expect(bob?.playing, isTrue);
      expect(bob?.displayName, 'Bob');
    });
  });
}
