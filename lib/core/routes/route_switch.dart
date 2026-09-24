import 'package:flutter/material.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/auth/login/login_screen.dart';
import 'package:memory_companion/features/auth/register/register_screen.dart';
import 'package:memory_companion/features/auth/splash/splash_page.dart';
import 'package:memory_companion/features/daily_challenge/daily_challenge_page.dart';
import 'package:memory_companion/features/friends/friends_screen.dart';
import 'package:memory_companion/features/home/home_screen.dart';
import 'package:memory_companion/features/level_map/level_map_page.dart';
import 'package:memory_companion/features/minigames/hub/minigame_hub_screen.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';
import 'package:memory_companion/features/profile/profile_screen.dart';
import 'package:memory_companion/features/settings/settings_screen.dart';
import 'package:memory_companion/features/shop/shop_screen.dart';
import 'package:memory_companion/features/statistics/statistics_screen.dart';
import 'package:memory_companion/features/versus/duel_page.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/versus_screen.dart';

class RouteSwitch {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Mini-games declare their own routes; see [MinigameRegistry].
    final minigameRoute = MinigameRegistry.routeFor(settings);
    if (minigameRoute != null) return minigameRoute;

    switch (settings.name) {
      case RoutePaths.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case RoutePaths.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RoutePaths.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RoutePaths.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RoutePaths.versus:
        return MaterialPageRoute(builder: (_) => const VersusScreen());
      case RoutePaths.duel:
        final duel = settings.arguments;
        if (duel is Duel) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => DuelPage(duel: duel),
          );
        }
        return MaterialPageRoute(builder: (_) => const VersusScreen());
      case RoutePaths.friends:
        return MaterialPageRoute(builder: (_) => const FriendsScreen());
      case RoutePaths.shop:
        return MaterialPageRoute(builder: (_) => const ShopScreen());
      case RoutePaths.levelMap:
        return MaterialPageRoute(
          builder: (_) => const LevelMapPage(regionName: 'Forest of Riddles'),
        );
      case RoutePaths.minigameHub:
        return MaterialPageRoute(builder: (_) => const MinigameHubScreen());
      case RoutePaths.dailyChallenge:
        return MaterialPageRoute(builder: (_) => const DailyChallengePage());
      case RoutePaths.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case RoutePaths.statistics:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());
      case RoutePaths.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
