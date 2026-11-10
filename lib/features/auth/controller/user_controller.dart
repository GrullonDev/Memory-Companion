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

  return ref
      .watch(authStateChangesProvider)
      .maybeWhen(
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

}

final userControllerProvider = AsyncNotifierProvider<UserController, void>(
  UserController.new,
);
