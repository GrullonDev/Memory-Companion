import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/routes/tab_root_scope.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/core/widgets/floating_bob.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/versus_player.dart';
import 'package:memory_companion/features/versus/widget/duel_game_picker.dart';
import 'package:memory_companion/features/versus/widget/duel_list_card.dart';
import 'package:memory_companion/features/versus/widget/versus_player_card.dart';
import 'package:memory_companion/features/versus/widget/versus_top_bar.dart';
import 'package:memory_companion/features/versus/widget/vs_badge.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// The player, their opponent and one "Play" button that finds a match:
/// online, nearby, or against the computer when nobody is around.
class VersusScreen extends ConsumerWidget {
  const VersusScreen({super.key});

  static const _tabIndex = 1;

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onPlay(BuildContext context, WidgetRef ref) async {
    final mode = await showModalBottomSheet<PlayMode>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      showDragHandle: true,
      builder: (_) => const _PlayModeSheet(),
    );
    if (mode == null || !context.mounted) return;

    final languageCode = Localizations.localeOf(context).languageCode;
    final phase = ValueNotifier(
      mode == PlayMode.online ? MatchPhase.online : MatchPhase.nearby,
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SearchingDialog(phase: phase),
    );

    final result = await ref
        .read(versusControllerProvider.notifier)
        .findMatch(
          mode: mode,
          languageCode: languageCode,
          onPhase: (value) => phase.value = value,
        );

    if (!context.mounted) return;
    Navigator.of(context).pop();
    phase.dispose();
    switch (result) {
      case DuelMatch(:final duel):
        _play(context, duel);
      case CpuMatch(:final level):
        _notify(
          context,
          AppLocale.matchCpuFallback
              .getString(context)
              .replaceAll('{level}', level.labelKey.getString(context)),
        );
        Navigator.of(context).pushNamed(RoutePaths.cpuDuel, arguments: level);
    }
  }

  void _play(BuildContext context, Duel duel) {
    Navigator.of(context).pushNamed(RoutePaths.duel, arguments: duel);
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, Duel duel) async {
    final ok = await ref.read(versusControllerProvider.notifier).decline(duel);
    if (!ok && context.mounted) {
      _notify(context, AppLocale.socialActionFailed.getString(context));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Opening Versus marks the player online for their friends.
    ref.watch(socialPresenceProvider);

    final wallet = ref.watch(walletControllerProvider);
    final versus = ref.watch(versusControllerProvider);

    return TabRootScope(
      isHome: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: HomeBottomNav(
          activeIndex: _tabIndex,
          onTap: (index) => RoutePaths.navigateToTab(context, index),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              VersusTopBar(coins: wallet.value ?? 0),
              const SizedBox(height: 28),
              AsyncValueView<VersusState>(
                value: versus,
                minHeight: 420,
                onRetry: () => ref.invalidate(versusControllerProvider),
                data: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FloatingBob(
                      phase: 0,
                      child: _PlayerCardFromModel(player: state.me),
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
                      child: switch (state.rivalCard) {
                        final rival? => _PlayerCardFromModel(player: rival),
                        null => const _UnknownOpponentCard(),
                      },
                    ),
                    if (state.rivals.length > 1) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _RivalPicker(state: state),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _PlayButton(onTap: () => _onPlay(context, ref)),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocale.versusHowItWorks.getString(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              if (versus.value case final state?) ...[
                const SizedBox(height: 24),
                DuelListCard(
                  state: state,
                  showWaiting: false,
                  onPlay: (duel) => _play(context, duel),
                  onDecline: (duel) => _decline(context, ref, duel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: AppColors.primaryFixedDim,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 4,
        shadowColor: const Color(0x40E6B400),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.onPrimaryFixed,
              ),
              const SizedBox(width: 10),
              Text(
                AppLocale.playLabel.getString(context).toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onPrimaryFixed,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The game, then online or nearby: all the "Play" button asks for.
class _PlayModeSheet extends ConsumerWidget {
  const _PlayModeSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocale.playModeTitle.getString(context),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            DuelGamePicker(
              selected: ref.watch(selectedDuelGameProvider),
              onSelected: ref.read(selectedDuelGameProvider.notifier).select,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _PlayModeOption(
              icon: Icons.public_rounded,
              color: AppColors.skyStrong,
              titleKey: AppLocale.playOnlineTitle,
              messageKey: AppLocale.playOnlineMessage,
              mode: PlayMode.online,
            ),
            const SizedBox(height: AppSpacing.md),
            const _PlayModeOption(
              icon: Icons.bluetooth_searching_rounded,
              color: AppColors.secondaryContainer,
              titleKey: AppLocale.playLocalTitle,
              messageKey: AppLocale.playLocalMessage,
              mode: PlayMode.nearby,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayModeOption extends StatelessWidget {
  const _PlayModeOption({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.messageKey,
    required this.mode,
  });

  final IconData icon;
  final Color color;
  final String titleKey;
  final String messageKey;
  final PlayMode mode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Icon(icon, size: 32, color: color),
        title: Text(
          titleKey.getString(context),
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          messageKey.getString(context),
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).pop(mode),
      ),
    );
  }
}

/// Shown while matchmaking looks online, then nearby.
class _SearchingDialog extends StatelessWidget {
  const _SearchingDialog({required this.phase});

  final ValueListenable<MatchPhase> phase;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primaryFixedDim),
          const SizedBox(width: 20),
          Flexible(
            child: ValueListenableBuilder(
              valueListenable: phase,
              builder: (context, value, _) => Text(
                switch (value) {
                  MatchPhase.online => AppLocale.searchingOnlineLabel,
                  MatchPhase.nearby => AppLocale.searchingNearbyLabel,
                }.getString(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Which friend to challenge, when there is more than one.
class _RivalPicker extends ConsumerWidget {
  const _RivalPicker({required this.state});

  final VersusState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocale.chooseRivalLabel.getString(context),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final friend in state.rivals)
              ChoiceChip(
                label: Text(displayNameOr(context, friend.name)),
                selected: friend.uid == state.rival?.uid,
                onSelected: (_) => ref
                    .read(versusControllerProvider.notifier)
                    .selectRival(friend.uid),
              ),
          ],
        ),
      ],
    );
  }
}

/// The opponent's seat before anyone is in it.
class _UnknownOpponentCard extends StatelessWidget {
  const _UnknownOpponentCard();

  @override
  Widget build(BuildContext context) {
    return VersusPlayerCard(
      name: AppLocale.opponentLabel.getString(context),
      rankLabel: AppLocale.findOpponentLabel.getString(context),
      level: 0,
      powerValue: '? XP',
      powerProgress: 0,
      formWins: const [],
      accentColor: AppColors.onSurfaceVariant,
      reversed: true,
    );
  }
}

class _PlayerCardFromModel extends StatelessWidget {
  const _PlayerCardFromModel({required this.player});

  final VersusPlayer player;

  @override
  Widget build(BuildContext context) {
    return VersusPlayerCard(
      name: displayNameOr(context, player.name),
      rankLabel: player.rankKey.getString(context),
      level: player.level,
      powerValue: '${NumberFormat.decimalPattern().format(player.totalXp)} XP',
      powerProgress: player.levelProgress,
      formWins: player.formWins,
      accentColor: player.accentColor,
      reversed: player.reversed,
    );
  }
}
