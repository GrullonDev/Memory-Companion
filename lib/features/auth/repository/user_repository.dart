import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/core/firebase/firestore_database.dart';
import 'package:memory_companion/features/auth/model/user.dart';

/// Repository for managing user data in Firestore
class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  /// Se resuelve en el primer uso, no al construir: crear un
  /// repositorio no debe exigir que Firebase ya esté inicializado.
  FirebaseFirestore get _firestore => _injected ?? appFirestore();

  /// Create a new user document in Firestore
  /// Called right after authentication
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toFirestore(), SetOptions(merge: true));
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
      final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (displayName != null) data['displayName'] = displayName;
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      if (avatarSeed != null) data['avatarSeed'] = avatarSeed;

      await _firestore.collection('users').doc(uid).update(data);
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
