import 'package:flutter/material.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/auth/complete_profile/complete_profile_screen.dart';
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
import 'package:memory_companion/features/history_search/history_search_screen.dart';
import 'package:memory_companion/features/statistics/statistics_screen.dart';
import 'package:memory_companion/features/versus/cpu/cpu_duel_page.dart';
import 'package:memory_companion/features/versus/cpu/cpu_opponent.dart';
import 'package:memory_companion/features/versus/duel_page.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/versus_screen.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:memory_companion/core/localization/app_locale.dart';

class RouteSwitch {
  /// The routes the app starts with: only [initialRoute] itself.
  ///
  /// Flutter's default splits a name like `/splash` into `/` and `/splash`
  /// and pushes both. This app has no `/` route, so that hidden first route
  /// was the "not found" screen, waiting under Home for a back press.
  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) => [
    onGenerateRoute(RouteSettings(name: initialRoute)),
  ];

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Mini-games declare their own routes; see [MinigameRegistry].
    final minigameRoute = MinigameRegistry.routeFor(settings);
    if (minigameRoute != null) return minigameRoute;

    switch (settings.name) {
      case RoutePaths.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashPage(),
        );
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
      case RoutePaths.cpuDuel:
        final level = settings.arguments;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              CpuDuelPage(level: level is CpuLevel ? level : CpuLevel.normal),
        );
      case RoutePaths.completeProfile:
        return MaterialPageRoute(builder: (_) => const CompleteProfileScreen());
      case RoutePaths.friends:
        return MaterialPageRoute(builder: (_) => const FriendsScreen());
      case RoutePaths.shop:
        return MaterialPageRoute(builder: (_) => const ShopScreen());
      case RoutePaths.levelMap:
        return MaterialPageRoute(builder: (_) => const LevelMapPage());
      case RoutePaths.minigameHub:
        return MaterialPageRoute(builder: (_) => const MinigameHubScreen());
      case RoutePaths.dailyChallenge:
        return MaterialPageRoute(builder: (_) => const DailyChallengePage());
      case RoutePaths.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case RoutePaths.statistics:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());
      case RoutePaths.historySearch:
        return MaterialPageRoute(builder: (_) => const HistorySearchScreen());
      case RoutePaths.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const _RouteNotFound(),
        );
    }
  }
}

/// Shown for a route name nobody serves. It may be the only route left, so
/// it always offers a way home instead of relying on back.
class _RouteNotFound extends StatelessWidget {
  const _RouteNotFound();

  void _goHome(BuildContext context) => Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(RoutePaths.home, (_) => false);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goHome(context);
      },
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocale.routeNotFound.getString(context)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _goHome(context),
                child: Text(AppLocale.backToHome.getString(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
