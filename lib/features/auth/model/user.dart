/// User model for Firestore storage
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Game stats
  final int level;
  final int currentXp;
  final int totalCoins;
  final int gamesWon;
  final int totalMoves;
  final int bestStreak;
  final String rank;
  final int avatarSeed;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.level = 1,
    this.currentXp = 0,
    this.totalCoins = 0,
    this.gamesWon = 0,
    this.totalMoves = 0,
    this.bestStreak = 0,
    this.rank = 'Novice',
    this.avatarSeed = 0,
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'level': level,
      'currentXp': currentXp,
      'totalCoins': totalCoins,
      'gamesWon': gamesWon,
      'totalMoves': totalMoves,
      'bestStreak': bestStreak,
      'rank': rank,
      'avatarSeed': avatarSeed,
    };
  }

  /// Create AppUser from Firestore document
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      phoneNumber: data['phoneNumber'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      level: data['level'] ?? 1,
      currentXp: data['currentXp'] ?? 0,
      totalCoins: data['totalCoins'] ?? 0,
      gamesWon: data['gamesWon'] ?? 0,
      totalMoves: data['totalMoves'] ?? 0,
      bestStreak: data['bestStreak'] ?? 0,
      rank: data['rank'] ?? 'Novice',
      avatarSeed: data['avatarSeed'] ?? 0,
    );
  }

  /// Create a copy with new values
  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    int? level,
    int? currentXp,
    int? totalCoins,
    int? gamesWon,
    int? totalMoves,
    int? bestStreak,
    String? rank,
    int? avatarSeed,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      totalCoins: totalCoins ?? this.totalCoins,
      gamesWon: gamesWon ?? this.gamesWon,
      totalMoves: totalMoves ?? this.totalMoves,
      bestStreak: bestStreak ?? this.bestStreak,
      rank: rank ?? this.rank,
      avatarSeed: avatarSeed ?? this.avatarSeed,
    );
  }
}
