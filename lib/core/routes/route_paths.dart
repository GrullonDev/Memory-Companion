import 'package:flutter/widgets.dart';

class RoutePaths {
  static const String splash = '/splash';
  static const String home = '/home';
  static const String versus = '/versus';
  static const String friends = '/friends';
  static const String shop = '/shop';
  static const String boardSolo = '/board/solo';

  /// Bottom-nav tab destinations, indexed the same way as [HomeBottomNav].
  static const List<String> tabs = [home, versus, friends, shop];

  /// Switches the visible bottom-nav tab without stacking screens.
  static void navigateToTab(BuildContext context, int index) {
    Navigator.of(context).pushReplacementNamed(tabs[index]);
  }
}
