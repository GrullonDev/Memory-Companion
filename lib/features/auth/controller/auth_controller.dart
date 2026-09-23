import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memory_companion/core/firebase/firebase_initialization.dart';
import 'package:memory_companion/features/auth/controller/user_controller.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final googleSignInProvider = Provider<GoogleSignIn>((ref) => GoogleSignIn());

/// Emits the current [User] (or null when signed out) as Firebase reports
/// it, so the splash screen can route straight to home for a returning
/// session instead of always landing on the login form.
final authStateChangesProvider = StreamProvider<User?>((ref) async* {
  // Nadie toca `FirebaseAuth.instance` antes de que Firebase exista.
  await ref.watch(firebaseInitializationProvider.future);
  yield* ref.watch(firebaseAuthProvider).authStateChanges();
});

/// Wraps [FirebaseAuth]'s email/password flows. State is [AsyncLoading]
/// while a request is in flight and [AsyncError] on failure, so the login
/// and register screens can drive their button spinner and error snackbar
/// directly off it via `ref.listen`.
class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  /// Firebase, garantizando que esté inicializado.
  ///
  /// El arranque ya no lo espera, así que cada acción explícita del jugador
  /// —entrar, registrarse, recuperar contraseña— se asegura por su cuenta.
  Future<FirebaseAuth> get _readyAuth async {
    await ref.read(firebaseInitializationProvider.future);
    return _auth;
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = await _readyAuth;
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = await _readyAuth;
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final trimmedName = displayName.trim();
      if (trimmedName.isNotEmpty) {
        await credential.user?.updateDisplayName(trimmedName);
      }

      // Create user in Firestore
      await ref.read(userControllerProvider.notifier).createNewUser(
        email: email.trim(),
        displayName: trimmedName.isNotEmpty ? trimmedName : null,
      );
    });
  }

  /// Returns `false` (without touching [state]) when the user dismisses the
  /// Google account picker, so callers can skip showing an error for that.
  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    await ref.read(firebaseInitializationProvider.future);
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
      final userCredential = await _auth.signInWithCredential(credential);

      // Create user in Firestore if it's a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await ref.read(userControllerProvider.notifier).createNewUser(
          email: userCredential.user?.email ?? '',
          displayName: userCredential.user?.displayName,
          photoUrl: userCredential.user?.photoURL,
        );
      }
    });
    return true;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = await _readyAuth;
      await auth.sendPasswordResetEmail(email: email.trim());
    });
  }

  Future<void> signOut() => _auth.signOut();
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
