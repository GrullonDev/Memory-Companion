import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/auth/splash/controller/splash_controller.dart';
import 'package:memory_companion/features/auth/splash/splash_screen.dart';

/// Connects the boot logic to navigation. Kept separate so [SplashScreen]
/// stays a plain, stateless UI widget.
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(splashBootProvider, (previous, next) {
      next.whenOrNull(
        data: (_) => Navigator.pushReplacementNamed(context, RoutePaths.login),
      );
    });

    return const SplashScreen();
  }
}
