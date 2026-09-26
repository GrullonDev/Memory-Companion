import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memory_companion/features/auth/model/user.dart';
import 'package:memory_companion/features/auth/repository/user_repository.dart';
import 'package:memory_companion/features/auth/controller/auth_controller.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Provides the current authenticated user data
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);

  return ref.watch(authStateChangesProvider).maybeWhen(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return userRepository.watchUser(firebaseUser.uid);
    },
    orElse: () => Stream.value(null),
  );
});

/// Controller for user operations
class UserController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  UserRepository get _userRepository => ref.read(userRepositoryProvider);
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  /// Create a new user in Firestore after authentication
  Future<void> createNewUser({
    required String email,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final appUser = AppUser(
        uid: user.uid,
        email: email,
        displayName: displayName ?? user.displayName,
        photoUrl: photoUrl ?? user.photoURL,
        phoneNumber: phoneNumber ?? user.phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _userRepository.createUser(appUser);
    });
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    int? avatarSeed,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _userRepository.updateUserProfile(
        uid: user.uid,
        displayName: displayName,
        photoUrl: photoUrl,
        avatarSeed: avatarSeed,
      );
    });
  }

  /// Update game statistics
  Future<void> updateGameStats({
    int? gamesWon,
    int? totalMoves,
    int? bestStreak,
    int? totalXp,
    int? totalCoins,
    String? rank,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _userRepository.updateGameStats(
        uid: user.uid,
        gamesWon: gamesWon,
        totalMoves: totalMoves,
        bestStreak: bestStreak,
        totalXp: totalXp,
        totalCoins: totalCoins,
        rank: rank,
      );
    });
  }

  /// Record a game win
  Future<void> recordGameWin({
    required int coinsEarned,
    required int xpEarned,
    required int movesUsed,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _userRepository.recordGameWin(
        user.uid,
        coinsEarned: coinsEarned,
        xpEarned: xpEarned,
        movesUsed: movesUsed,
      );
    });
  }

  /// Add coins
  Future<void> addCoins(int amount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _userRepository.addCoins(user.uid, amount);
    });
  }

  /// Add XP
  Future<void> addXp(int amount) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _userRepository.addXp(user.uid, amount);
    });
  }
}

final userControllerProvider = AsyncNotifierProvider<UserController, void>(
  UserController.new,
);
