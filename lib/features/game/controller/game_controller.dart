import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/auth/controller/user_controller.dart';
import 'package:memory_companion/features/game/model/match.dart';
import 'package:memory_companion/features/game/repository/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

/// Provides user's match history
final userMatchHistoryProvider = StreamProvider<List<Match>>((ref) {
  final matchRepository = ref.watch(matchRepositoryProvider);

  return ref.watch(authStateChangesProvider).maybeWhen(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value([]);
      return matchRepository.getUserMatches(firebaseUser.uid);
    },
    orElse: () => Stream.value([]),
  );
});

/// Provides user's match statistics
final userStatsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final matchRepository = ref.watch(matchRepositoryProvider);

  return ref.watch(authStateChangesProvider).maybeWhen(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value({});
      return matchRepository.getUserStats(firebaseUser.uid).asStream();
    },
    orElse: () => Stream.value({}),
  );
});

/// Controller for game operations
class GameController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  MatchRepository get _matchRepository => ref.read(matchRepositoryProvider);
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  /// Complete a solo game and save results
  Future<void> completeSoloGame({
    required int score,
    required int moves,
    required int secondsElapsed,
    required int timeLimit,
    required bool won,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Calculate rewards
      final rewards = Match.calculateRewards(
        score: score,
        moves: moves,
        timeLimit: timeLimit,
        secondsElapsed: secondsElapsed,
        won: won,
      );

      // Create match record
      final match = Match(
        id: const Uuid().v4(),
        userId: user.uid,
        gameMode: 'solo',
        score: score,
        moves: moves,
        secondsElapsed: secondsElapsed,
        timeLimit: timeLimit,
        coinsEarned: rewards['coins']!,
        xpEarned: rewards['xp']!,
        won: won,
        playedAt: DateTime.now(),
      );

      // Save match
      await _matchRepository.saveMatch(match);

      // Update user stats if they won
      if (won) {
        await ref.read(userControllerProvider.notifier).recordGameWin(
          coinsEarned: rewards['coins']!,
          xpEarned: rewards['xp']!,
          movesUsed: moves,
        );

        // Check for level up
        await _checkLevelUp(user.uid);
      } else {
        // Small XP for playing
        await ref.read(userControllerProvider.notifier).addXp(rewards['xp']!);
      }
    });
  }

  /// Check if user should level up
  Future<void> _checkLevelUp(String uid) async {
    try {
      final userRepository = ref.read(authControllerProvider);
      // This would need to be implemented in UserRepository
      // For now, we'll keep it simple
    } catch (e) {
      // Silent fail for level checking
    }
  }

  /// Get match history
  Future<List<Match>> getMatchHistory() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final stats = await _matchRepository.getUserStats(user.uid);
      // Return first batch
      return _matchRepository.getUserMatches(user.uid).first;
    } catch (e) {
      return [];
    }
  }

  /// Get game statistics
  Future<Map<String, dynamic>> getGameStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      return await _matchRepository.getUserStats(user.uid);
    } catch (e) {
      return {};
    }
  }
}

final gameControllerProvider = AsyncNotifierProvider<GameController, void>(
  GameController.new,
);
