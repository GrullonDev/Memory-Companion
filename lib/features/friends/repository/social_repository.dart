import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/core/firebase/firestore_database.dart';
import 'package:memory_companion/features/friends/model/friendship.dart';
import 'package:memory_companion/features/friends/model/public_player.dart';

/// What happened to a friend request.
enum FriendRequestOutcome {
  sent,

  /// They had already asked the player, so asking back accepts it.
  accepted,
  alreadyFriends,
  alreadyPending,
}

/// Friends and public profiles, in Firestore.
///
/// Social data lives only in the cloud (see docs/OFFLINE_FIRST.md §7): it is
/// about other people, so there is nothing a local copy could be the source
/// of truth for. The access rules are in `firestore.rules`.
class SocialRepository {
  SocialRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  /// Resolved on first use, so building the repository never requires
  /// Firebase to be initialized.
  FirebaseFirestore get _firestore => _injected ?? appFirestore();

  CollectionReference<Map<String, dynamic>> get _index =>
      _firestore.collection('user_index');

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection('friendships');

  /// Writes the player's public profile and marks them as seen now.
  Future<void> publishProfile({
    required String uid,
    required String displayName,
    required int avatarSeed,
    required int level,
    required int totalXp,
    required String friendCode,
  }) {
    return _index.doc(uid).set({
      'displayName': displayName,
      'avatarSeed': avatarSeed,
      'level': level,
      'totalXp': totalXp,
      'friendCode': friendCode,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Whether the player is in a duel right now, for their friends' lists.
  Future<void> setPlaying(String uid, {required bool playing}) {
    return _index.doc(uid).set({
      'playing': playing,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<PublicPlayer?> findByCode(String code) async {
    final query = await _index
        .where('friendCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.single;
    return PublicPlayer.fromFirestore(doc.id, doc.data());
  }

  /// The public profiles of [uids], keyed by uid. Missing players are left
  /// out.
  Stream<Map<String, PublicPlayer>> watchPlayers(List<String> uids) {
    if (uids.isEmpty) return Stream.value(const {});
    // `whereIn` takes at most 30 values; a friend list longer than that
    // shows its first 30.
    final ids = uids.take(30).toList();
    return _index
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map(
          (snapshot) => {
            for (final doc in snapshot.docs)
              doc.id: PublicPlayer.fromFirestore(doc.id, doc.data()),
          },
        );
  }

  /// Every friendship and pending request involving [uid].
  Stream<List<Friendship>> watchFriendships(String uid) {
    return _friendships
        .where('members', arrayContains: uid)
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs)
              Friendship.fromFirestore(doc.id, doc.data()),
          ],
        );
  }

  /// Sends [from]'s request to [to], or accepts theirs if they asked first.
  Future<FriendRequestOutcome> sendRequest({
    required String from,
    required String to,
  }) {
    final ref = _friendships.doc(Friendship.idFor(from, to));
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data != null) {
        final existing = Friendship.fromFirestore(snapshot.id, data);
        if (existing.isAccepted) return FriendRequestOutcome.alreadyFriends;
        if (existing.requestedBy == from) {
          return FriendRequestOutcome.alreadyPending;
        }
        transaction.update(ref, _acceptance);
        return FriendRequestOutcome.accepted;
      }

      transaction.set(ref, {
        'members': Friendship.membersOf(from, to),
        'requestedBy': from,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return FriendRequestOutcome.sent;
    });
  }

  Future<void> accept(String friendshipId) =>
      _friendships.doc(friendshipId).update(_acceptance);

  /// Declines or cancels a request, or ends a friendship.
  Future<void> remove(String friendshipId) =>
      _friendships.doc(friendshipId).delete();

  static Map<String, Object> get _acceptance => {
    'status': 'accepted',
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
