import 'package:flutter/material.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/auth/splash/splash_screen.dart';

class RouteSwitch {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutePaths.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
