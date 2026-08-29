import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/auth/controller/auth_controller.dart';

enum PhoneAuthStep { enterPhone, codeSent, verified }

class PhoneAuthState {
  const PhoneAuthState({
    this.step = PhoneAuthStep.enterPhone,
    this.isLoading = false,
    this.verificationId,
    this.errorMessage,
  });

  final PhoneAuthStep step;
  final bool isLoading;
  final String? verificationId;
  final Object? errorMessage;

  PhoneAuthState copyWith({
    PhoneAuthStep? step,
    bool? isLoading,
    String? verificationId,
    Object? errorMessage,
  }) {
    return PhoneAuthState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage,
    );
  }
}

/// Drives Firebase's callback-based phone sign-in flow: send an SMS code to
/// [phoneNumber], then confirm it with [confirmCode]. Kept separate from
/// [AuthController] because this flow needs to carry a `verificationId`
/// between its two steps instead of resolving in a single call.
class PhoneAuthController extends Notifier<PhoneAuthState> {
  @override
  PhoneAuthState build() => const PhoneAuthState();

  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  Future<void> sendCode(String phoneNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
        state = state.copyWith(isLoading: false, step: PhoneAuthStep.verified);
      },
      verificationFailed: (e) {
        state = state.copyWith(isLoading: false, errorMessage: e);
      },
      codeSent: (verificationId, _) {
        state = state.copyWith(
          isLoading: false,
          step: PhoneAuthStep.codeSent,
          verificationId: verificationId,
        );
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> confirmCode(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      await _auth.signInWithCredential(credential);
      state = state.copyWith(isLoading: false, step: PhoneAuthStep.verified);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e);
    }
  }

  void reset() => state = const PhoneAuthState();
}

final phoneAuthControllerProvider =
    NotifierProvider<PhoneAuthController, PhoneAuthState>(
      PhoneAuthController.new,
    );
