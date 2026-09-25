import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Firestore errors that retrying cannot fix.
const _permanentCodes = {
  'permission-denied',
  'unauthenticated',
  'failed-precondition',
  'invalid-argument',
  'not-found',
};

/// Riverpod's retry policy, minus Firebase errors that never go away.
///
/// Riverpod 3 retries a failing provider up to ten times with backoff,
/// about 40 seconds in all, and screens that await it show their spinner
/// the whole time. A rule that denies a read denies it every time, so
/// those errors surface at once and the screen offers "Retry" instead.
Duration? appProviderRetry(int retryCount, Object error) {
  if (error is FirebaseException && _permanentCodes.contains(error.code)) {
    return null;
  }
  return ProviderContainer.defaultRetry(retryCount, error);
}
