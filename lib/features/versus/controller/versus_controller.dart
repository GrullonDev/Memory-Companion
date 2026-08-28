import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/versus/model/versus_player.dart';

class VersusController extends AsyncNotifier<VersusMatchup> {
  @override
  Future<VersusMatchup> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const VersusMatchup(
      player: VersusPlayer(
        name: 'PlayerOne',
        rankLabel: 'Master Rank',
        level: 42,
        powerValue: '8,450',
        powerProgress: 0.72,
        formWins: [true, true, true, false],
        accentColor: AppColors.secondaryContainer,
      ),
      rival: VersusPlayer(
        name: 'RivalPro',
        rankLabel: 'Grandmaster',
        level: 55,
        powerValue: '9,100',
        powerProgress: 0.86,
        formWins: [true, true, true, false],
        accentColor: AppColors.error,
        reversed: true,
      ),
    );
  }

  /// Simulates matchmaking — there is no real multiplayer backend yet, so
  /// this just waits briefly before the caller hands off to a match.
  Future<void> findOpponent() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
  }
}

final versusControllerProvider =
    AsyncNotifierProvider<VersusController, VersusMatchup>(
      VersusController.new,
    );
