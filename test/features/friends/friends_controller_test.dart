import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/friends/repository/social_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SocialRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = SocialRepository(firestore: firestore);
  });

  ProviderContainer open({String? uid = 'alice'}) {
    final container = ProviderContainer(
      overrides: [
        socialUidProvider.overrideWith((ref) async => uid),
        socialRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(friendsControllerProvider, (_, _) {});
    return container;
  }

  Future<void> publish(String uid, String name) => repository.publishProfile(
    uid: uid,
    displayName: name,
    avatarSeed: 0,
    level: 2,
    totalXp: 1500,
    friendCode: FriendCode.fromUid(uid),
  );

  /// Espera a que los streams de Firestore lleguen al controlador.
  Future<FriendsState> waitFor(
    ProviderContainer container,
    bool Function(FriendsState state) condition,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      final state = container.read(friendsControllerProvider).value;
      if (state != null && condition(state)) return state;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('el estado de Amigos nunca cumplió la condición');
  }

  test('sin cuenta no hay amigos ni se puede agregar', () async {
    final container = open(uid: null);
    final state = await container.read(friendsControllerProvider.future);
    expect(state.isSignedIn, isFalse);
    expect(
      await container
          .read(friendsControllerProvider.notifier)
          .addByCode(FriendCode.fromUid('bob')),
      AddFriendResult.signedOut,
    );
  });

  test('separa amigos, solicitudes recibidas y enviadas', () async {
    await publish('bob', 'Bob');
    await publish('carol', 'Carol');
    await publish('dave', 'Dave');
    await repository.sendRequest(from: 'alice', to: 'bob');
    await repository.sendRequest(from: 'bob', to: 'alice');
    await repository.sendRequest(from: 'carol', to: 'alice');
    await repository.sendRequest(from: 'alice', to: 'dave');

    final state = await open().read(friendsControllerProvider.future);
    expect(state.friendCode, FriendCode.fromUid('alice'));
    expect([for (final f in state.friends) f.name], ['Bob']);
    expect(state.friends.single.status, FriendStatus.online);
    expect(state.friends.single.level, 2);
    expect([for (final f in state.incoming) f.name], ['Carol']);
    expect([for (final f in state.outgoing) f.name], ['Dave']);
  });

  test('agregar por código explica cada caso', () async {
    await publish('bob', 'Bob');
    final container = open();
    await container.read(friendsControllerProvider.future);
    final controller = container.read(friendsControllerProvider.notifier);

    expect(await controller.addByCode('abc'), AddFriendResult.invalidCode);
    expect(
      await controller.addByCode(FriendCode.fromUid('alice')),
      AddFriendResult.self,
    );
    expect(
      await controller.addByCode(FriendCode.fromUid('nadie')),
      AddFriendResult.notFound,
    );
    expect(
      await controller.addByCode(FriendCode.fromUid('bob').toLowerCase()),
      AddFriendResult.sent,
    );
    expect(
      await controller.addByCode(FriendCode.fromUid('bob')),
      AddFriendResult.alreadyPending,
    );

    final state = await waitFor(container, (s) => s.outgoing.isNotEmpty);
    expect(state.outgoing.single.uid, 'bob');
    expect(state.outgoing.single.relation, FriendRelation.outgoing);
  });

  test('aceptar una solicitud la convierte en amistad', () async {
    await publish('carol', 'Carol');
    await repository.sendRequest(from: 'carol', to: 'alice');
    final container = open();
    final before = await container.read(friendsControllerProvider.future);

    final ok = await container
        .read(friendsControllerProvider.notifier)
        .accept(before.incoming.single);
    expect(ok, isTrue);

    final after = await waitFor(container, (s) => s.friends.isNotEmpty);
    expect(after.incoming, isEmpty);
    expect(after.friends.single.name, 'Carol');

    await container
        .read(friendsControllerProvider.notifier)
        .remove(after.friends.single);
    await waitFor(container, (s) => s.friends.isEmpty);
  });

  test('los amigos en línea van primero', () async {
    await publish('zoe', 'Zoe');
    await publish('adam', 'Adam');
    // Adam lleva horas sin abrir la app.
    await firestore.collection('user_index').doc('adam').update({
      'lastSeenAt': DateTime.now().subtract(const Duration(hours: 3)),
    });
    for (final other in ['zoe', 'adam']) {
      await repository.sendRequest(from: 'alice', to: other);
      await repository.sendRequest(from: other, to: 'alice');
    }

    final state = await open().read(friendsControllerProvider.future);
    expect([for (final f in state.friends) f.name], ['Zoe', 'Adam']);
    expect(state.friends.last.status, FriendStatus.offline);
  });
}
