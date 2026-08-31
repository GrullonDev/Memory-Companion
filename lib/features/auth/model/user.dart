import 'package:memory_companion/features/player/model/player_level.dart';

/// El documento `users/{uid}` de Firestore.
///
/// Cambio respecto al modelo anterior: se guardaba `level` junto a
/// `currentXp` (el XP *dentro* del nivel), y nada escribía nunca `level`.
/// Ahora el único dato persistido es [totalXp] —acumulado de por vida y
/// monótono— y [level] es un getter derivado. Ver `player_level.dart`.
class AppUser {
  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.totalXp = 0,
    this.totalCoins = 0,
    this.gamesWon = 0,
    this.totalMoves = 0,
    this.bestStreak = 0,
    this.rank = 'Novice',
    this.avatarSeed = 0,
  });

  /// Reconstruye desde Firestore, migrando los documentos heredados.
  ///
  /// Un documento sin `totalXp` viene del modelo antiguo: se calcula a partir
  /// de `level` y `currentXp`, que siguen ahí. La migración es determinista y
  /// solo depende de campos presentes, así que puede correr en el cliente.
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    final storedTotalXp = data['totalXp'];

    return AppUser(
      uid: uid,
      email: (data['email'] as String?) ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      createdAt: data['createdAt']?.toDate() as DateTime? ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() as DateTime? ?? DateTime.now(),
      totalXp: storedTotalXp is int
          ? storedTotalXp
          : migratedTotalXp(
              legacyLevel: (data['level'] as int?) ?? 1,
              legacyCurrentXp: (data['currentXp'] as int?) ?? 0,
            ),
      totalCoins: (data['totalCoins'] as int?) ?? 0,
      gamesWon: (data['gamesWon'] as int?) ?? 0,
      totalMoves: (data['totalMoves'] as int?) ?? 0,
      bestStreak: (data['bestStreak'] as int?) ?? 0,
      rank: (data['rank'] as String?) ?? 'Novice',
      avatarSeed: (data['avatarSeed'] as int?) ?? 0,
    );
  }

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// XP acumulado de por vida. Monótono: nunca baja.
  final int totalXp;
  final int totalCoins;
  final int gamesWon;
  final int totalMoves;
  final int bestStreak;
  final String rank;
  final int avatarSeed;

  /// Derivado de [totalXp]. No se persiste ni se sincroniza.
  int get level => levelFromTotalXp(totalXp);

  /// XP conseguido dentro del nivel actual.
  int get xpIntoCurrentLevel => xpIntoLevel(totalXp);

  /// XP que pide el nivel actual para completarse.
  int get xpNeededForCurrentLevel => xpForLevel(level);

  /// Escribe a Firestore.
  ///
  /// No escribe `level` ni `currentXp`: son derivados, y un derivado que
  /// viaja es un conflicto esperando a ocurrir. Los campos heredados que ya
  /// existan en el documento se dejan intactos a propósito — son la vía de
  /// vuelta si la migración resultara estar mal.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'totalXp': totalXp,
      'totalCoins': totalCoins,
      'gamesWon': gamesWon,
      'totalMoves': totalMoves,
      'bestStreak': bestStreak,
      'rank': rank,
      'avatarSeed': avatarSeed,
    };
  }

  AppUser copyWith({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
    int? totalXp,
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
      totalXp: totalXp ?? this.totalXp,
      totalCoins: totalCoins ?? this.totalCoins,
      gamesWon: gamesWon ?? this.gamesWon,
      totalMoves: totalMoves ?? this.totalMoves,
      bestStreak: bestStreak ?? this.bestStreak,
      rank: rank ?? this.rank,
      avatarSeed: avatarSeed ?? this.avatarSeed,
    );
  }
}
