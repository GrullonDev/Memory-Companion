/// Represents a completed game/match
class Match {
  final String id;
  final String userId;
  final String gameMode; // 'solo', 'versus', 'daily_challenge', etc.
  final int score;
  final int moves;
  final int secondsElapsed;
  final int timeLimit;
  final int coinsEarned;
  final int xpEarned;
  final bool won;
  final DateTime playedAt;

  // For versus games
  final String? opponentId;
  final String? opponentName;
  final int? opponentScore;

  Match({
    required this.id,
    required this.userId,
    required this.gameMode,
    required this.score,
    required this.moves,
    required this.secondsElapsed,
    required this.timeLimit,
    required this.coinsEarned,
    required this.xpEarned,
    required this.won,
    required this.playedAt,
    this.opponentId,
    this.opponentName,
    this.opponentScore,
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'gameMode': gameMode,
      'score': score,
      'moves': moves,
      'secondsElapsed': secondsElapsed,
      'timeLimit': timeLimit,
      'coinsEarned': coinsEarned,
      'xpEarned': xpEarned,
      'won': won,
      'playedAt': playedAt,
      'opponentId': opponentId,
      'opponentName': opponentName,
      'opponentScore': opponentScore,
    };
  }

  /// Create Match from Firestore document
  factory Match.fromFirestore(Map<String, dynamic> data, String id) {
    return Match(
      id: id,
      userId: data['userId'] ?? '',
      gameMode: data['gameMode'] ?? 'solo',
      score: data['score'] ?? 0,
      moves: data['moves'] ?? 0,
      secondsElapsed: data['secondsElapsed'] ?? 0,
      timeLimit: data['timeLimit'] ?? 90,
      coinsEarned: data['coinsEarned'] ?? 0,
      xpEarned: data['xpEarned'] ?? 0,
      won: data['won'] ?? false,
      playedAt: data['playedAt']?.toDate() ?? DateTime.now(),
      opponentId: data['opponentId'],
      opponentName: data['opponentName'],
      opponentScore: data['opponentScore'],
    );
  }

  /// Calculate rewards based on game performance
  static Map<String, int> calculateRewards({
    required int score,
    required int moves,
    required int timeLimit,
    required int secondsElapsed,
    required bool won,
  }) {
    if (!won) {
      // Small penalty XP for playing even if losing
      return {'coins': 0, 'xp': 10};
    }

    // Base rewards
    int coins = 50 + (score ~/ 100);
    int xp = 100 + (score ~/ 50);

    // Time bonus (up to 50% bonus)
    if (secondsElapsed < timeLimit ~/ 2) {
      final timeBonus = ((timeLimit - secondsElapsed) / timeLimit * 50).toInt();
      xp += timeBonus;
      coins += timeBonus ~/ 2;
    }

    // Efficiency bonus (fewer moves = more reward)
    final optimalMoves = 8; // Minimum moves for 8 pairs
    if (moves <= optimalMoves + 5) {
      final efficiencyBonus = 50;
      coins += efficiencyBonus;
      xp += efficiencyBonus;
    }

    return {'coins': coins, 'xp': xp};
  }
}
