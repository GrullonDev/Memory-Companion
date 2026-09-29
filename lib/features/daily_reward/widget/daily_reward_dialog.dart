import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/confetti_overlay.dart';
import 'package:memory_companion/features/daily_reward/controller/daily_reward_controller.dart';
import 'package:memory_companion/features/daily_reward/model/daily_reward.dart';
import 'package:memory_companion/features/daily_reward/widget/daily_reward_card.dart';

Future<void> showDailyRewardDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const DailyRewardDialog(),
  );
}

/// The daily chest, opened: the week's track, the chest itself wiggling
/// until it is claimed, and what it paid once it is.
class DailyRewardDialog extends ConsumerStatefulWidget {
  const DailyRewardDialog({super.key});

  @override
  ConsumerState<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends ConsumerState<DailyRewardDialog>
    with TickerProviderStateMixin {
  DailyRewardClaim? _claimed;
  bool _busy = false;

  /// The chest's idle wiggle, inviting the tap.
  late final AnimationController _wiggle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// The burst when it opens.
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wiggle.stop();
    } else if (_claimed == null && !_wiggle.isAnimating) {
      _wiggle.repeat();
    }
  }

  @override
  void dispose() {
    _wiggle.dispose();
    _burst.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final claim = await ref
        .read(dailyRewardControllerProvider.notifier)
        .claim();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _claimed = claim;
    });
    _wiggle.stop();
    if (claim == null) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _burst.value = 1;
    } else {
      _burst.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = ref.watch(dailyRewardControllerProvider).value;
    final claimed = _claimed;

    if (status == null) {
      return const Dialog(
        child: SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final reward = claimed?.reward ?? status.reward;
    final canClaim = status.available && claimed == null;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.streak,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        AppLocale.dailyRewardStreakDays
                            .getString(context)
                            .replaceAll('{n}', '${status.streak}'),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _WeekTrack(status: status),
                const SizedBox(height: AppSpacing.xl),
                _Chest(
                  wiggle: _wiggle,
                  burst: _burst,
                  open: claimed != null,
                  chestDay: reward.isChestDay,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (claimed != null)
                  _Payout(reward: claimed.reward)
                else
                  Text(
                    canClaim
                        ? AppLocale.dailyRewardMultiplierToday
                              .getString(context)
                              .replaceAll(
                                '{x}',
                                multiplierLabel(reward.multiplier),
                              )
                        : AppLocale.dailyRewardComeBack
                              .getString(context)
                              .replaceAll(
                                '{x}',
                                multiplierLabel(reward.multiplier),
                              ),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: canClaim
                      ? FilledButton.icon(
                          onPressed: _busy ? null : _claim,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.streak,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(
                              AppSize.touchComfortable,
                            ),
                          ),
                          icon: const Icon(Icons.redeem_rounded),
                          label: Text(
                            AppLocale.dailyRewardClaim.getString(context),
                          ),
                        )
                      : OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppSize.touchMin,
                            ),
                          ),
                          child: Text(
                            AppLocale.dailyRewardClose.getString(context),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (claimed != null)
            const Positioned.fill(
              child: IgnorePointer(child: ConfettiOverlay()),
            ),
        ],
      ),
    );
  }
}

/// This week of the streak: past days ticked, today (or tomorrow) lit, and
/// the chest waiting on the seventh.
class _WeekTrack extends StatelessWidget {
  const _WeekTrack({required this.status});

  final DailyRewardStatus status;

  @override
  Widget build(BuildContext context) {
    final claimedUpTo = status.available ? status.streak - 1 : status.streak;
    final next = claimedUpTo + 1;
    return Row(
      children: [
        for (final day in status.weekDays)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _DayTile(
                day: day,
                reward: DailyRewardSchedule.rewardFor(day, dateKey: ''),
                done: day <= claimedUpTo,
                next: day == next,
              ),
            ),
          ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.reward,
    required this.done,
    required this.next,
  });

  final int day;
  final DailyReward reward;
  final bool done;
  final bool next;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chest = day % DailyRewardSchedule.chestEvery == 0;
    final background = done
        ? AppColors.streakSoft
        : next
        ? AppColors.streak
        : AppColors.surfaceContainerLow;
    final foreground = next ? Colors.white : AppColors.onSurface;

    return Semantics(
      label: AppLocale.dailyRewardDayLabel
          .getString(context)
          .replaceAll('{n}', '$day'),
      selected: next,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: chest ? Border.all(color: AppColors.sunDeep, width: 2) : null,
        ),
        child: Column(
          children: [
            Text(
              '$day',
              style: textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : chest
                  ? Icons.inventory_2_rounded
                  : Icons.monetization_on_rounded,
              size: AppSize.iconSm,
              color: done
                  ? AppColors.streakStrong
                  : next
                  ? Colors.white
                  : AppColors.sunDeep,
            ),
            const SizedBox(height: AppSpacing.xxs),
            FittedBox(
              child: Text(
                '${reward.coins}',
                style: textTheme.labelSmall?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chest extends StatelessWidget {
  const _Chest({
    required this.wiggle,
    required this.burst,
    required this.open,
    required this.chestDay,
  });

  final Animation<double> wiggle;
  final Animation<double> burst;
  final bool open;
  final bool chestDay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([wiggle, burst]),
      builder: (context, child) {
        // A shake in the first third of each loop, then a rest.
        final t = wiggle.value;
        final angle = !open && t < 0.33
            ? math.sin(t / 0.33 * math.pi * 4) * 0.12
            : 0.0;
        final pop = open ? 1 + 0.3 * math.sin(burst.value * math.pi) : 1.0;
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: pop, child: child),
        );
      },
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.sunSoft,
              (chestDay ? AppColors.sun : AppColors.streakSoft).withValues(
                alpha: 0.6,
              ),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          open
              ? Icons.celebration_rounded
              : chestDay
              ? Icons.inventory_2_rounded
              : Icons.card_giftcard_rounded,
          size: 64,
          color: chestDay ? AppColors.sunStrong : AppColors.streakDeep,
        ),
      ),
    );
  }
}

/// What the chest paid, line by line.
class _Payout extends StatelessWidget {
  const _Payout({required this.reward});

  final DailyReward reward;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final line = textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900);
    return Column(
      children: [
        Text(
          AppLocale.dailyRewardClaimedTitle.getString(context),
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.streakStrong,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.lg,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  color: AppColors.sunDeep,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('+${reward.totalCoins}', style: line),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.violetDeep),
                const SizedBox(width: AppSpacing.xs),
                Text('+${reward.totalXp} XP', style: line),
              ],
            ),
          ],
        ),
        if (reward.chestBonus case final bonus?) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            (bonus == ChestBonus.coins
                    ? AppLocale.dailyRewardSurpriseCoins
                    : AppLocale.dailyRewardSurpriseXp)
                .getString(context)
                .replaceAll('{n}', '${reward.chestAmount}'),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.sunStrong,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}
