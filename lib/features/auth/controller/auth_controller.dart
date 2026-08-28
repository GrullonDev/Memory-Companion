import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

/// Emits the current [User] (or null when signed out) as Firebase reports
/// it, so the splash screen can route straight to home for a returning
/// session instead of always landing on the login form.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Wraps [FirebaseAuth]'s email/password flows. State is [AsyncLoading]
/// while a request is in flight and [AsyncError] on failure, so the login
/// and register screens can drive their button spinner and error snackbar
/// directly off it via `ref.listen`.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final trimmedName = displayName.trim();
      if (trimmedName.isNotEmpty) {
        await credential.user?.updateDisplayName(trimmedName);
      }
    });
  }

  /// Returns `false` (without touching [state]) when the user dismisses the
  /// Google account picker, so callers can skip showing an error for that.
  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    final googleUser = await ref.read(googleSignInProvider).signIn();
    if (googleUser == null) {
      state = const AsyncData(null);
      return false;
    }
    state = await AsyncValue.guard(() async {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    });
    return true;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _auth.sendPasswordResetEmail(email: email.trim()),
    );
  }

  Future<void> signOut() => _auth.signOut();
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
