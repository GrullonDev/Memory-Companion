import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/features/auth/model/user.dart';

/// Repository for managing user data in Firestore
class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  /// Se resuelve en el primer uso, no al construir: crear un
  /// repositorio no debe exigir que Firebase ya esté inicializado.
  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Create a new user document in Firestore
  /// Called right after authentication
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(
            user.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      rethrow;
    }
  }

  /// Get user from Firestore by UID
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, uid);
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of user data changes
  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data()!, uid);
    });
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? photoUrl,
    int? avatarSeed,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) data['displayName'] = displayName;
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (avatarSeed != null) data['avatarSeed'] = avatarSeed;

      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Update game statistics
  Future<void> updateGameStats({
    required String uid,
    int? gamesWon,
    int? totalMoves,
    int? bestStreak,
    int? totalXp,
    int? totalCoins,
    String? rank,
  }) async {
    try {
      final data = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (gamesWon != null) data['gamesWon'] = gamesWon;
      if (totalMoves != null) data['totalMoves'] = totalMoves;
      if (bestStreak != null) data['bestStreak'] = bestStreak;
      if (totalXp != null) data['totalXp'] = totalXp;
      if (totalCoins != null) data['totalCoins'] = totalCoins;
      if (rank != null) data['rank'] = rank;

      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  /// Add coins to user's total
  Future<void> addCoins(String uid, int amount) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'totalCoins': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Suma XP al acumulado de por vida. El nivel se deriva, no se escribe.
  Future<void> addXp(String uid, int amount) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'totalXp': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Record a game win
  Future<void> recordGameWin(
    String uid, {
    required int coinsEarned,
    required int xpEarned,
    required int movesUsed,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'gamesWon': FieldValue.increment(1),
        'totalMoves': FieldValue.increment(movesUsed),
        'totalCoins': FieldValue.increment(coinsEarned),
        'totalXp': FieldValue.increment(xpEarned),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Update best streak
  Future<void> updateBestStreak(String uid, int streak) async {
    try {
      final user = await getUser(uid);
      if (user != null && streak > user.bestStreak) {
        await _firestore.collection('users').doc(uid).update({
          'bestStreak': streak,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete user data (when account is deleted)
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      rethrow;
    }
  }
}
