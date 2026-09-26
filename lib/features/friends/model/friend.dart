enum FriendStatus { online, inGame, offline }

/// Where a [Friend] stands with the player.
enum FriendRelation {
  friend,

  /// They sent the player a request.
  incoming,

  /// The player sent them a request.
  outgoing,
}

/// Someone on the Friends screen, as the list shows them.
class Friend {
  const Friend({
    required this.uid,
    required this.friendshipId,
    required this.name,
    required this.status,
    required this.relation,
    this.level = 1,
    this.avatarSeed = 0,
    this.totalXp = 0,
  });

  final String uid;
  final String friendshipId;
  final String name;
  final FriendStatus status;
  final FriendRelation relation;
  final int level;
  final int avatarSeed;
  final int totalXp;

  String get initials {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.single;
      return word.substring(0, word.length < 2 ? word.length : 2).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }
}
