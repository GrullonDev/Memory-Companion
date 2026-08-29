import 'package:flutter/widgets.dart';

/// One side of a [VersusMatchup] card.
class VersusPlayer {
  const VersusPlayer({
    required this.name,
    required this.rankLabel,
    required this.level,
    required this.powerValue,
    required this.powerProgress,
    required this.formWins,
    required this.accentColor,
    this.reversed = false,
  });

  final String name;
  final String rankLabel;
  final int level;
  final String powerValue;
  final double powerProgress;
  final List<bool> formWins;
  final Color accentColor;
  final bool reversed;
}

class VersusMatchup {
  const VersusMatchup({required this.player, required this.rival});

  final VersusPlayer player;
  final VersusPlayer rival;
}
