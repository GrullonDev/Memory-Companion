import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendshipStatus { pending, accepted }

/// A friend request, or an accepted friendship, between two players.
///
/// One document per pair, whose id is the two uids sorted and joined, so
/// the same two people can never hold two friendships.
class Friendship {
  const Friendship({
    required this.id,
    required this.members,
    required this.requestedBy,
    required this.status,
    this.createdAt,
  });

  factory Friendship.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return Friendship(
      id: id,
      members: List<String>.from(data['members'] as List? ?? const []),
      requestedBy: data['requestedBy'] as String? ?? '',
      status: data['status'] == 'accepted'
          ? FriendshipStatus.accepted
          : FriendshipStatus.pending,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  static List<String> membersOf(String a, String b) =>
      a.compareTo(b) <= 0 ? [a, b] : [b, a];

  static String idFor(String a, String b) => membersOf(a, b).join('_');

  final String id;

  /// Both uids, sorted.
  final List<String> members;
  final String requestedBy;
  final FriendshipStatus status;
  final DateTime? createdAt;

  String otherOf(String uid) =>
      members.firstWhere((member) => member != uid, orElse: () => uid);

  bool get isAccepted => status == FriendshipStatus.accepted;

  /// A request someone else sent to [uid].
  bool isIncomingFor(String uid) => !isAccepted && requestedBy != uid;
}
