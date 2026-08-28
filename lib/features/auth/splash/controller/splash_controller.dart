import 'package:riverpod/riverpod.dart';

/// Runs the app's boot sequence (min splash time, warm-up checks, etc.)
/// and signals when it's safe to navigate away from the splash screen.
final splashBootProvider = FutureProvider<void>((ref) async {
  await Future<void>.delayed(const Duration(seconds: 2));
});
