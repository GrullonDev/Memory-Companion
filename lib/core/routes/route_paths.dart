import 'package:flutter/widgets.dart';

class RoutePaths {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String versus = '/versus';

  /// Plays a duel; pass the `Duel` as `arguments`.
  static const String duel = '/versus/duel';

  /// Plays against the computer; pass the `CpuLevel` as `arguments`.
  static const String cpuDuel = '/versus/cpu';

  /// Asks a newly signed-in player for the name others will see.
  static const String completeProfile = '/complete-profile';
  static const String friends = '/friends';
  static const String shop = '/shop';
  static const String levelMap = '/level-map';
  static const String boardSolo = '/board/solo';
  static const String dailyChallenge = '/daily-challenge';
  static const String profile = '/profile';
  static const String statistics = '/statistics';

  /// Questions about the history in plain language, answered on the device.
  static const String historySearch = '/statistics/search';
  static const String settings = '/settings';
  static const String minigameHub = '/games';

  /// Bottom-nav tab destinations, indexed the same way as [HomeBottomNav].
  // The shop tab is hidden while plans are in development; its route still
  // resolves.
  static const List<String> tabs = [home, versus, friends /* , shop */];

  /// Switches the visible bottom-nav tab without stacking screens: the
  /// tab becomes the only route, so tabs never pile up and back from one
  /// is always handled by `TabRootScope`.
  static void navigateToTab(BuildContext context, int index) {
    Navigator.of(context).pushNamedAndRemoveUntil(tabs[index], (_) => false);
  }
}
