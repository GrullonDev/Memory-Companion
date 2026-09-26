import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memory_companion/features/level_map/model/level.dart';

/// Repository for managing game levels and progression in Firestore
class LevelRepository {
  LevelRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  /// Se resuelve en el primer uso, no al construir: crear un
  /// repositorio no debe exigir que Firebase ya esté inicializado.
  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Get all levels for a user
  Future<List<GameLevel>> getUserLevels(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('levels')
          .orderBy('levelNumber', descending: false)
          .get();

      return [
        for (final doc in snapshot.docs)
          GameLevel.fromFirestore(doc.data(), doc.id),
      ];
    } catch (e) {
      // Return generated default levels if not found
      return generateGameLevels(unlockedUpToLevel: 1);
    }
  }

  /// Get a specific level
  Future<GameLevel?> getLevel(String userId, int levelNumber) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('levels')
          .doc('level_$levelNumber')
          .get();

      if (!doc.exists) return null;
      return GameLevel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Initialize levels for a new user
  Future<void> initializeLevels(String userId) async {
    try {
      final batch = _firestore.batch();
      final defaultLevels = generateGameLevels(unlockedUpToLevel: 1);

      for (final level in defaultLevels) {
        final ref = _firestore
            .collection('users')
            .doc(userId)
            .collection('levels')
            .doc(level.id);
        batch.set(ref, level.toFirestore());
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Complete a level (mark as completed and unlock next)
  Future<void> completeLevel(
    String userId,
    int levelNumber,
    int score,
  ) async {
    try {
      final batch = _firestore.batch();

      // Update current level
      final currentLevelRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('levels')
          .doc('level_$levelNumber');

      batch.update(currentLevelRef, {
        'isCompleted': true,
        'bestScore': FieldValue.arrayUnion([score]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Unlock next level if exists
      if (levelNumber < 50) {
        final nextLevelRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('levels')
            .doc('level_${levelNumber + 1}');

        batch.update(nextLevelRef, {
          'isUnlocked': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of user's levels
  Stream<List<GameLevel>> watchUserLevels(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('levels')
        .orderBy('levelNumber', descending: false)
        .snapshots()
        .map((snapshot) {
      return [
        for (final doc in snapshot.docs)
          GameLevel.fromFirestore(doc.data(), doc.id),
      ];
    });
  }

  /// Get current level number (highest unlocked)
  Future<int> getCurrentLevelNumber(String userId) async {
    try {
      final levels = await getUserLevels(userId);
      int currentLevel = 1;
      for (final level in levels) {
        if (level.isUnlocked || level.isCompleted) {
          currentLevel = level.levelNumber;
        } else {
          break;
        }
      }
      return currentLevel;
    } catch (e) {
      return 1;
    }
  }
}
