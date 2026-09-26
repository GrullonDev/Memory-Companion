import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/friends/model/friendship.dart';
import 'package:memory_companion/features/friends/model/public_player.dart';
import 'package:memory_companion/features/friends/repository/social_repository.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/model/player_level.dart';

final socialRepositoryProvider = Provider<SocialRepository>(
  (ref) => SocialRepository(),
);

/// The clock presence is judged against. Overridden in tests.
final socialClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// The signed-in player's Firebase uid, or null without an account.
///
/// Friends and duels need an account: other players have to be able to
/// find you, and Firestore has to know who is writing.
final socialUidProvider = FutureProvider<String?>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  return user?.uid;
});

/// Publishes the player's public profile and marks them online.
///
/// Watched by the Friends and Versus screens, so presence is written when
/// the player opens them and whenever their name or XP changes while they
/// are there. There is no background heartbeat.
final socialPresenceProvider = FutureProvider.autoDispose<void>((ref) async {
  final uid = await ref.watch(socialUidProvider.future);
  if (uid == null) return;
  final player = await ref.watch(localPlayerProvider.future);
  await ref
      .read(socialRepositoryProvider)
      .publishProfile(
        uid: uid,
        displayName: player.displayName,
        avatarSeed: player.avatarSeed,
        level: levelFromTotalXp(player.totalXp),
        totalXp: player.totalXp,
        friendCode: FriendCode.fromUid(uid),
      );
});

final friendshipsProvider = StreamProvider.autoDispose
    .family<List<Friendship>, String>(
      (ref, uid) => ref.watch(socialRepositoryProvider).watchFriendships(uid),
    );

/// Public profiles for a comma-separated, sorted list of uids. A string key
/// so the family compares by value.
final publicPlayersProvider = StreamProvider.autoDispose
    .family<Map<String, PublicPlayer>, String>((ref, joinedUids) {
      final uids = joinedUids.split(',')..removeWhere((uid) => uid.isEmpty);
      return ref.watch(socialRepositoryProvider).watchPlayers(uids);
    });

class FriendsState {
  const FriendsState({
    required String this.uid,
    required String this.friendCode,
    this.friends = const [],
    this.incoming = const [],
    this.outgoing = const [],
  });

  const FriendsState.signedOut()
    : uid = null,
      friendCode = null,
      friends = const [],
      incoming = const [],
      outgoing = const [];

  final String? uid;

  /// The code the player shares so others can add them.
  final String? friendCode;

  /// Accepted friends: whoever is online first, then by name.
  final List<Friend> friends;

  /// Requests waiting for the player's answer.
  final List<Friend> incoming;

  /// Requests the player sent that are still unanswered.
  final List<Friend> outgoing;

  bool get isSignedIn => uid != null;
}

enum AddFriendResult {
  sent,
  accepted,
  invalidCode,
  notFound,
  self,
  alreadyFriends,
  alreadyPending,
  signedOut,
  failed,
}

/// The player's friends and friend requests, live from Firestore.
class FriendsController extends AsyncNotifier<FriendsState> {
  @override
  Future<FriendsState> build() async {
    final uid = await ref.watch(socialUidProvider.future);
    if (uid == null) return const FriendsState.signedOut();

    final friendships = await ref.watch(friendshipsProvider(uid).future);
    final others = [for (final f in friendships) f.otherOf(uid)]..sort();
    final players = await ref.watch(
      publicPlayersProvider(others.join(',')).future,
    );
    final now = ref.read(socialClockProvider)();

    final friends = <Friend>[];
    final incoming = <Friend>[];
    final outgoing = <Friend>[];
    for (final friendship in friendships) {
      final otherUid = friendship.otherOf(uid);
      final player = players[otherUid];
      final relation = friendship.isAccepted
          ? FriendRelation.friend
          : friendship.isIncomingFor(uid)
          ? FriendRelation.incoming
          : FriendRelation.outgoing;
      final friend = Friend(
        uid: otherUid,
        friendshipId: friendship.id,
        name: player?.displayName ?? '',
        status: player?.statusAt(now) ?? FriendStatus.offline,
        relation: relation,
        level: player?.level ?? 1,
        avatarSeed: player?.avatarSeed ?? 0,
        totalXp: player?.totalXp ?? 0,
      );
      switch (relation) {
        case FriendRelation.friend:
          friends.add(friend);
        case FriendRelation.incoming:
          incoming.add(friend);
        case FriendRelation.outgoing:
          outgoing.add(friend);
      }
    }

    friends.sort((a, b) {
      final byStatus = a.status.index.compareTo(b.status.index);
      if (byStatus != 0) return byStatus;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return FriendsState(
      uid: uid,
      friendCode: FriendCode.fromUid(uid),
      friends: friends,
      incoming: incoming,
      outgoing: outgoing,
    );
  }

  SocialRepository get _repository => ref.read(socialRepositoryProvider);

  /// Looks up [input] as a friend code and sends that player a request.
  Future<AddFriendResult> addByCode(String input) async {
    final uid = await ref.read(socialUidProvider.future);
    if (uid == null) return AddFriendResult.signedOut;

    final code = FriendCode.normalize(input);
    if (code == null) return AddFriendResult.invalidCode;
    if (code == FriendCode.fromUid(uid)) return AddFriendResult.self;

    try {
      final player = await _repository.findByCode(code);
      if (player == null) return AddFriendResult.notFound;
      if (player.uid == uid) return AddFriendResult.self;

      final outcome = await _repository.sendRequest(from: uid, to: player.uid);
      return switch (outcome) {
        FriendRequestOutcome.sent => AddFriendResult.sent,
        FriendRequestOutcome.accepted => AddFriendResult.accepted,
        FriendRequestOutcome.alreadyFriends => AddFriendResult.alreadyFriends,
        FriendRequestOutcome.alreadyPending => AddFriendResult.alreadyPending,
      };
    } on Exception {
      return AddFriendResult.failed;
    }
  }

  /// Accepts an incoming request. Returns false if it could not be saved.
  Future<bool> accept(Friend friend) =>
      _guard(() => _repository.accept(friend.friendshipId));

  /// Declines or cancels a request, or removes a friend.
  Future<bool> remove(Friend friend) =>
      _guard(() => _repository.remove(friend.friendshipId));

  Future<bool> _guard(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on Exception {
      return false;
    }
  }
}

final friendsControllerProvider =
    AsyncNotifierProvider<FriendsController, FriendsState>(
      FriendsController.new,
    );
