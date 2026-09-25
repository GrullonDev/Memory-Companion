import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/auth/controller/auth_controller.dart';
import 'package:memory_companion/features/auth/controller/user_controller.dart';
import 'package:memory_companion/features/auth/model/user.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// Saves the name a newly signed-in player chose.
///
/// Phone sign-in creates the Firebase account with no name and no
/// `users/{uid}` document, which is why the name showed up blank. The name
/// is written to all three places that show it:
///
/// * the local profile, which the Home, Versus and Friends read, and which
///   the sync queue carries to Firestore;
/// * the Firebase account, which decides whether this step is still due;
/// * the `users/{uid}` document, created here if the sync has not yet.
class CompleteProfileController extends AsyncNotifier<void> {
  static const minLength = 2;
  static const maxLength = 24;

  @override
  Future<void> build() async {}

  static bool isValid(String name) {
    final length = name.trim().length;
    return length >= minLength && length <= maxLength;
  }

  Future<void> save(String name) async {
    final trimmed = name.trim();
    if (!isValid(trimmed)) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user == null) throw StateError('No authenticated user');

      final player = await ref.read(localPlayerProvider.future);
      await ref
          .read(playerRepositoryProvider)
          .updateIdentity(localId: player.localId, displayName: trimmed);
      await user.updateDisplayName(trimmed);
      await user.reload();

      // Firestore only resolves a write once the server acknowledges it,
      // which never happens offline. The local profile already holds the
      // name, so the player moves on without waiting for the cloud.
      unawaited(
        _saveCloudProfile(
          uid: user.uid,
          name: trimmed,
          email: user.email ?? '',
          phoneNumber: user.phoneNumber,
        ),
      );
    });
  }

  Future<void> _saveCloudProfile({
    required String uid,
    required String name,
    required String email,
    String? phoneNumber,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    try {
      // The rules keep `createdAt` fixed, so an existing document is only
      // updated, never re-created.
      if (await repository.userExists(uid)) {
        await repository.updateUserProfile(uid: uid, displayName: name);
      } else {
        final now = DateTime.now();
        await repository.createUser(
          AppUser(
            uid: uid,
            email: email,
            displayName: name,
            phoneNumber: phoneNumber,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    } on Exception {
      // The sync queue still carries the name from the local profile.
    }
  }
}

final completeProfileControllerProvider =
    AsyncNotifierProvider<CompleteProfileController, void>(
      CompleteProfileController.new,
    );
