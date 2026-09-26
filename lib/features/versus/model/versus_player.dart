import 'package:flutter/widgets.dart';

import 'package:memory_companion/core/localization/app_locale.dart';

/// One side of the Versus screen's face-off.
class VersusPlayer {
  const VersusPlayer({
    required this.name,
    required this.level,
    required this.totalXp,
    required this.levelProgress,
    required this.formWins,
    required this.accentColor,
    this.reversed = false,
  });

  final String name;
  final int level;

  /// Lifetime XP: the card's "power".
  final int totalXp;

  /// Progress through the current level, 0 to 1.
  final double levelProgress;

  /// Recent duel results, oldest first; true is a win.
  final List<bool> formWins;
  final Color accentColor;
  final bool reversed;

  /// The rank title for [level].
  String get rankKey => rankKeyFor(level);

  static String rankKeyFor(int level) {
    if (level >= 35) return AppLocale.rankGrandmaster;
    if (level >= 20) return AppLocale.rankMaster;
    if (level >= 10) return AppLocale.rankExpert;
    if (level >= 5) return AppLocale.rankApprentice;
    return AppLocale.rankRookie;
  }
}
