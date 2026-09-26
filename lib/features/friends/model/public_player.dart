import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/player/model/player_level.dart';

/// What other players can see about someone: their `user_index` document.
///
/// Deliberately small. Email, phone and coins stay in the private `users`
/// document, which only its owner can read.
class PublicPlayer {
  const PublicPlayer({
    required this.uid,
    required this.displayName,
    this.avatarSeed = 0,
    this.totalXp = 0,
    this.friendCode,
    this.lastSeenAt,
    this.playing = false,
  });

  factory PublicPlayer.fromFirestore(String uid, Map<String, dynamic> data) {
    final lastSeen = data['lastSeenAt'];
    return PublicPlayer(
      uid: uid,
      displayName: (data['displayName'] as String?) ?? '',
      avatarSeed: (data['avatarSeed'] as num?)?.toInt() ?? 0,
      totalXp: (data['totalXp'] as num?)?.toInt() ?? 0,
      friendCode: data['friendCode'] as String?,
      lastSeenAt: lastSeen is Timestamp ? lastSeen.toDate() : null,
      playing: data['playing'] == true,
    );
  }

  /// How recently a player must have been seen to count as online. Presence
  /// is written when they open Friends or Versus, not on a timer, so the
  /// window is generous.
  static const Duration onlineWindow = Duration(minutes: 10);

  final String uid;
  final String displayName;
  final int avatarSeed;
  final int totalXp;
  final String? friendCode;
  final DateTime? lastSeenAt;

  /// True while they are playing a duel.
  final bool playing;

  int get level => levelFromTotalXp(totalXp);

  FriendStatus statusAt(DateTime now) {
    final seen = lastSeenAt;
    if (seen == null || now.difference(seen) > onlineWindow) {
      return FriendStatus.offline;
    }
    return playing ? FriendStatus.inGame : FriendStatus.online;
  }
}
