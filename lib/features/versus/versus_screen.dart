import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/core/widgets/floating_bob.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/model/versus_player.dart';
import 'package:memory_companion/features/versus/widget/versus_player_card.dart';
import 'package:memory_companion/features/versus/widget/versus_top_bar.dart';
import 'package:memory_companion/features/versus/widget/vs_badge.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

class VersusScreen extends ConsumerWidget {
  const VersusScreen({super.key});

  Future<void> _startDuel(BuildContext context, WidgetRef ref) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryFixedDim),
            const SizedBox(width: 20),
            Text(AppLocale.searchingOpponentLabel.getString(dialogContext)),
          ],
        ),
      ),
    );

    await ref.read(versusControllerProvider.notifier).findOpponent();

    if (!context.mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushNamed(RoutePaths.boardSolo);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);
    final matchup = ref.watch(versusControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        activeIndex: 1,
        onTap: (index) => RoutePaths.navigateToTab(context, index),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            VersusTopBar(coins: wallet.value ?? 0),
            const SizedBox(height: 28),
            AsyncValueView(
              value: matchup,
              minHeight: 420,
              onRetry: () => ref.invalidate(versusControllerProvider),
              data: (context, VersusMatchup matchup) => Column(
                children: [
                  FloatingBob(
                    phase: 0,
                    child: _PlayerCardFromModel(player: matchup.player),
                  ),
                  SizedBox(
                    height: 140,
                    child: Center(
                      child: FloatingBob(
                        phase: 0.5,
                        amplitude: 6,
                        child: const VsBadge(),
                      ),
                    ),
                  ),
                  FloatingBob(
                    phase: 0.25,
                    child: _PlayerCardFromModel(player: matchup.rival),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Material(
                color: AppColors.primaryFixedDim,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 4,
                shadowColor: const Color(0x40E6B400),
                child: InkWell(
                  onTap: () => _startDuel(context, ref),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sports_esports_rounded,
                        color: AppColors.onPrimaryFixed,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocale.startDuel.getString(context),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.onPrimaryFixed,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCardFromModel extends StatelessWidget {
  const _PlayerCardFromModel({required this.player});

  final VersusPlayer player;

  @override
  Widget build(BuildContext context) {
    return VersusPlayerCard(
      name: player.name,
      rankLabel: player.rankLabel,
      level: player.level,
      powerValue: player.powerValue,
      powerProgress: player.powerProgress,
      formWins: player.formWins,
      accentColor: player.accentColor,
      reversed: player.reversed,
    );
  }
}
