import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memory_companion/features/game/model/match.dart';

/// Repository for managing match/game history in Firestore
class MatchRepository {
  final FirebaseFirestore _firestore;

  MatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save a completed match to Firestore
  Future<void> saveMatch(Match match) async {
    try {
      await _firestore
          .collection('users')
          .doc(match.userId)
          .collection('matches')
          .doc(match.id)
          .set(match.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's match history
  Stream<List<Match>> getUserMatches(String userId, {int limit = 50}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('matches')
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return [
        for (final doc in snapshot.docs)
          Match.fromFirestore(doc.data(), doc.id),
      ];
    });
  }

  /// Get recent wins only
  Stream<List<Match>> getUserWins(String userId, {int limit = 20}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('matches')
        .where('won', isEqualTo: true)
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return [
        for (final doc in snapshot.docs)
          Match.fromFirestore(doc.data(), doc.id),
      ];
    });
  }

  /// Get matches by game mode
  Stream<List<Match>> getUserMatchesByMode(
    String userId,
    String gameMode, {
    int limit = 50,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('matches')
        .where('gameMode', isEqualTo: gameMode)
        .orderBy('playedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return [
        for (final doc in snapshot.docs)
          Match.fromFirestore(doc.data(), doc.id),
      ];
    });
  }

  /// Get statistics for a user
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('matches')
          .get();

      int totalMatches = snapshot.docs.length;
      int totalWins = 0;
      int totalCoins = 0;
      int totalXp = 0;
      int totalMoves = 0;
      int bestScore = 0;
      int averageTime = 0;
      List<int> times = [];

      for (final doc in snapshot.docs) {
        final match = Match.fromFirestore(doc.data(), doc.id);
        if (match.won) totalWins++;
        totalCoins += match.coinsEarned;
        totalXp += match.xpEarned;
        totalMoves += match.moves;
        if (match.score > bestScore) bestScore = match.score;
        times.add(match.secondsElapsed);
      }

      if (times.isNotEmpty) {
        averageTime = times.reduce((a, b) => a + b) ~/ times.length;
      }

      return {
        'totalMatches': totalMatches,
        'totalWins': totalWins,
        'winRate': totalMatches > 0 ? (totalWins / totalMatches * 100) : 0,
        'totalCoinsEarned': totalCoins,
        'totalXpEarned': totalXp,
        'totalMoves': totalMoves,
        'bestScore': bestScore,
        'averageTime': averageTime,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a match (for testing or cleanup)
  Future<void> deleteMatch(String userId, String matchId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('matches')
          .doc(matchId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
