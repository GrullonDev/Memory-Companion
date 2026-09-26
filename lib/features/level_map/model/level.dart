/// Game level with progressive difficulty
class GameLevel {
  const GameLevel({
    required this.id,
    required this.levelNumber,
    required this.timeLimit,
    required this.cardsCount,
    required this.isUnlocked,
    required this.isCompleted,
    required this.bestScore,
  });

  final String id;
  final int levelNumber;
  final int timeLimit; // seconds
  final int cardsCount;
  final bool isUnlocked;
  final bool isCompleted;
  final int bestScore;

  GameLevel copyWith({
    bool? isUnlocked,
    bool? isCompleted,
    int? bestScore,
  }) {
    return GameLevel(
      id: id,
      levelNumber: levelNumber,
      timeLimit: timeLimit,
      cardsCount: cardsCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
    );
  }

  /// Difficulty indicator based on level (1-5 stars)
  int get difficulty {
    if (levelNumber <= 5) return 1;
    if (levelNumber <= 10) return 2;
    if (levelNumber <= 15) return 3;
    if (levelNumber <= 20) return 4;
    return 5;
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'levelNumber': levelNumber,
      'timeLimit': timeLimit,
      'cardsCount': cardsCount,
      'isUnlocked': isUnlocked,
      'isCompleted': isCompleted,
      'bestScore': bestScore,
      'updatedAt': DateTime.now(),
    };
  }

  /// Create from Firestore document
  factory GameLevel.fromFirestore(Map<String, dynamic> data, String id) {
    return GameLevel(
      id: id,
      levelNumber: data['levelNumber'] as int? ?? 1,
      timeLimit: data['timeLimit'] as int? ?? 90,
      cardsCount: data['cardsCount'] as int? ?? 16,
      isUnlocked: data['isUnlocked'] as bool? ?? false,
      isCompleted: data['isCompleted'] as bool? ?? false,
      bestScore: data['bestScore'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'GameLevel(levelNumber: $levelNumber, difficulty: $difficulty)';
}

/// Generate levels dynamically based on game progression
List<GameLevel> generateGameLevels({
  required int unlockedUpToLevel,
  Map<int, int>? bestScores,
  Map<int, bool>? completedLevels,
}) {
  final levels = <GameLevel>[];

  for (int i = 1; i <= 50; i++) {
    final isUnlocked = i <= unlockedUpToLevel;
    final isCompleted = completedLevels?[i] ?? false;
    final bestScore = bestScores?[i] ?? 0;

    // Progressive difficulty: every 5 levels, time decreases and cards increase
    final timeLimit = 90 - ((i - 1) ~/ 5) * 10; // Starts at 90s, decreases by 10s every 5 levels
    final cardsCount = 16 + ((i - 1) ~/ 5) * 2; // Starts at 16, increases by 2 every 5 levels

    levels.add(
      GameLevel(
        id: 'level_$i',
        levelNumber: i,
        timeLimit: (timeLimit < 30) ? 30 : timeLimit, // Minimum 30 seconds
        cardsCount: (cardsCount > 32) ? 32 : cardsCount, // Maximum 32 cards
        isUnlocked: isUnlocked,
        isCompleted: isCompleted,
        bestScore: bestScore,
      ),
    );
  }

  return levels;
}
