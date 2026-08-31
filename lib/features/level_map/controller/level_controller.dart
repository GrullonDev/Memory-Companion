import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/level_map/model/level.dart';
import 'package:memory_companion/features/level_map/repository/level_repository.dart';

final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  return LevelRepository();
});

/// Provides all levels for the current user
final userLevelsProvider = StreamProvider<List<GameLevel>>((ref) {
  final levelRepository = ref.watch(levelRepositoryProvider);

  return ref.watch(authStateChangesProvider).maybeWhen(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value([]);
      return levelRepository.watchUserLevels(firebaseUser.uid);
    },
    orElse: () => Stream.value([]),
  );
});

/// Provides the current level number
final currentLevelProvider = FutureProvider<int>((ref) async {
  final levelRepository = ref.watch(levelRepositoryProvider);
  final auth = FirebaseAuth.instance;

  final user = auth.currentUser;
  if (user == null) return 1;

  return levelRepository.getCurrentLevelNumber(user.uid);
});

/// Controller for level progression
class LevelController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  LevelRepository get _levelRepository => ref.read(levelRepositoryProvider);
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  /// Initialize levels for a new user
  Future<void> initializeLevels() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _levelRepository.initializeLevels(user.uid);
    });
  }

  /// Complete a level and unlock the next one
  Future<void> completeLevel({
    required int levelNumber,
    required int score,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _levelRepository.completeLevel(
        user.uid,
        levelNumber,
        score,
      );
    });
  }

  /// Get level details
  Future<GameLevel?> getLevel(int levelNumber) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _levelRepository.getLevel(user.uid, levelNumber);
  }
}

final levelControllerProvider = AsyncNotifierProvider<LevelController, void>(
  LevelController.new,
);
