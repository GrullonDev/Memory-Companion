import 'package:flutter/material.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/features/auth/splash/splash_page.dart';
import 'package:memory_companion/features/game/board/board_page.dart';
import 'package:memory_companion/features/home/home_screen.dart';
import 'package:memory_companion/features/home/widget/coming_soon_screen.dart';
import 'package:memory_companion/features/level_map/level_map_screen.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';
import 'package:memory_companion/features/versus/versus_screen.dart';

class RouteSwitch {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RoutePaths.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case RoutePaths.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RoutePaths.versus:
        return MaterialPageRoute(
          builder: (_) => VersusScreen(onStartDuel: () {}),
        );
      case RoutePaths.friends:
        return MaterialPageRoute(
          builder: (_) => const ComingSoonScreen(
            icon: Icons.groups,
            title: 'Friends',
            activeIndex: 2,
          ),
        );
      case RoutePaths.shop:
        return MaterialPageRoute(
          builder: (_) => const ComingSoonScreen(
            icon: Icons.storefront,
            title: 'Shop',
            activeIndex: 3,
          ),
        );
      case RoutePaths.levelMap:
        return MaterialPageRoute(
          builder: (context) => LevelMapScreen(
            regionName: 'Forest of Riddles',
            levels: const [
              LevelNode(number: 1, status: LevelStatus.completed),
              LevelNode(number: 2, status: LevelStatus.current),
              LevelNode(number: 3, status: LevelStatus.locked),
              LevelNode(number: 4, status: LevelStatus.locked),
            ],
            onSelectLevel: (level) =>
                Navigator.of(context).pushNamed(RoutePaths.boardSolo),
          ),
        );
      case RoutePaths.boardSolo:
        return MaterialPageRoute(builder: (_) => const BoardPage());
      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
