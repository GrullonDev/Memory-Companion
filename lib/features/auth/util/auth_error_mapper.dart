import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';

/// Maps a [FirebaseAuthException] (or any other error) thrown by the auth
/// flows to a localized, user-facing message.
String authErrorMessage(BuildContext context, Object error) {
  if (error is FirebaseAuthException) {
    final key = switch (error.code) {
      'invalid-email' => AppLocale.authErrorInvalidEmail,
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' => AppLocale.authErrorInvalidCredential,
      'email-already-in-use' => AppLocale.authErrorEmailAlreadyInUse,
      'weak-password' => AppLocale.authErrorWeakPassword,
      'network-request-failed' => AppLocale.authErrorNetworkFailed,
      'too-many-requests' => AppLocale.authErrorTooManyRequests,
      _ => AppLocale.authErrorGeneric,
    };
    return key.getString(context);
  }
  return AppLocale.authErrorGeneric.getString(context);
}
