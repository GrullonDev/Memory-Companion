import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/core/widgets/floating_bob.dart';
import 'package:memory_companion/core/widgets/pressable.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/widget/friend_tile.dart';
import 'package:memory_companion/features/friends/widget/social_sign_in_card.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/versus/controller/versus_controller.dart';
import 'package:memory_companion/features/versus/cpu/cpu_opponent.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/versus_player.dart';
import 'package:memory_companion/features/versus/widget/duel_list_card.dart';
import 'package:memory_companion/features/versus/widget/versus_player_card.dart';
import 'package:memory_companion/features/versus/widget/versus_top_bar.dart';
import 'package:memory_companion/features/versus/widget/vs_badge.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// The player against a friend, the button that challenges them, and the
/// player's duels.
class VersusScreen extends ConsumerWidget {
  const VersusScreen({super.key});

  static const _tabIndex = 1;
  static const _friendsTabIndex = 2;

  void _notify(BuildContext context, String messageKey) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(messageKey.getString(context))));
  }

  Future<void> _startDuel(BuildContext context, WidgetRef ref) async {
    final languageCode = Localizations.localeOf(context).languageCode;
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
            Flexible(
              child: Text(
                AppLocale.searchingOpponentLabel.getString(dialogContext),
              ),
            ),
          ],
        ),
      ),
    );

    final duel = await ref
        .read(versusControllerProvider.notifier)
        .startDuel(languageCode: languageCode);

    if (!context.mounted) return;
    Navigator.of(context).pop();
    if (duel == null) {
      _notify(context, AppLocale.duelCreateFailed);
      return;
    }
    _play(context, duel);
  }

  void _play(BuildContext context, Duel duel) {
    Navigator.of(context).pushNamed(RoutePaths.duel, arguments: duel);
  }

  Future<void> _decline(BuildContext context, WidgetRef ref, Duel duel) async {
    final ok = await ref.read(versusControllerProvider.notifier).decline(duel);
    if (!ok && context.mounted) _notify(context, AppLocale.socialActionFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Opening Versus marks the player online for their friends.
    ref.watch(socialPresenceProvider);

    final wallet = ref.watch(walletControllerProvider);
    final versus = ref.watch(versusControllerProvider);
    final canDuel = versus.value?.rival != null;

    return Scaffold(
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
                  if (!state.isSignedIn)
                    const SocialSignInCard()
                  else if (state.rivalCard case final rival?) ...[
                    FloatingBob(
                      phase: 0.25,
                      child: _PlayerCardFromModel(player: rival),
                    ),
                    if (state.rivals.length > 1) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _RivalPicker(state: state),
                    ],
                  ] else
                    _NoRivalCard(
                      onFindFriends: () =>
                          RoutePaths.navigateToTab(context, _friendsTabIndex),
                    ),
                ],
              ),
            ),
            if (canDuel) ...[
              const SizedBox(height: 28),
              _StartDuelButton(onTap: () => _startDuel(context, ref)),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppLocale.versusHowItWorks.getString(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Outside the social section on purpose: playing the computer
            // needs no account and no connection, so it never waits on them.
            const _CpuDuelCard(),
            if (versus.value case final state?) ...[
              const SizedBox(height: 24),
              DuelListCard(
                state: state,
                onPlay: (duel) => _play(context, duel),
                onDecline: (duel) => _decline(context, ref, duel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StartDuelButton extends StatelessWidget {
  const _StartDuelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Pressable(
        onTap: onTap,
        child: Material(
          color: AppColors.primaryFixedDim,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 4,
          shadowColor: const Color(0x40E6B400),
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

/// Plays a duel against the computer, at the chosen difficulty.
class _CpuDuelCard extends StatefulWidget {
  const _CpuDuelCard();

  @override
  State<_CpuDuelCard> createState() => _CpuDuelCardState();
}

class _CpuDuelCardState extends State<_CpuDuelCard> {
  var _level = CpuLevel.normal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.smart_toy_rounded,
                size: 36,
                color: AppColors.skyStrong,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.cpuDuelTitle.getString(context),
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppLocale.cpuDuelMessage.getString(context),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final level in CpuLevel.values)
                ChoiceChip(
                  label: Text(level.labelKey.getString(context)),
                  selected: level == _level,
                  onSelected: (_) => setState(() => _level = level),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AdaptiveButton(
            label: AppLocale.playLabel.getString(context),
            icon: Icons.play_arrow_rounded,
            onPressed: () => Navigator.of(
              context,
            ).pushNamed(RoutePaths.cpuDuel, arguments: _level),
          ),
        ],
      ),
    );
  }
}

class _NoRivalCard extends StatelessWidget {
  const _NoRivalCard({required this.onFindFriends});

  final VoidCallback onFindFriends;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.person_search_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocale.versusNoRivalTitle.getString(context),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocale.versusNoRivalMessage.getString(context),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AdaptiveButton(
            label: AppLocale.goToFriendsLabel.getString(context),
            icon: Icons.group_add_rounded,
            onPressed: onFindFriends,
          ),
        ],
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
