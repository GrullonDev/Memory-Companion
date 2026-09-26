import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/features/ladder/game_ladder.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/app_typography.dart';
import 'package:memory_companion/core/widgets/app_badge.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/core/widgets/app_progress_bar.dart';
import 'package:memory_companion/features/home/model/home_summary.dart';

/// Level ladder, next reward and streak in one strip.
///
/// The big number is the classic game's ladder — the level the Play button
/// opens on the map — and the bar fills towards its next ladder reward
/// (see [LevelRewards]). Every other game keeps its own ladder, listed as
/// chips underneath, mini-games included. The number used to come from lifetime XP, which rose
/// far slower than the map: a player on level 7 of the map read "Nivel 1".
///
/// All three numbers used to live only on the Profile, two taps away, even
/// though the app already stored them — so the Home showed a player no
/// evidence that yesterday counted. Surfacing them here is the cheapest
/// retention change available: the bar is visibly short of full, and the
/// exact XP gap is stated in words.
///
/// The streak badge is an invitation when the streak is zero and a thing
/// worth protecting once it isn't. It never scolds.
class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({super.key, required this.summary, this.onTap});

  final HomeSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final numberFormat = NumberFormat.decimalPattern();
    final levelLabel = AppLocale.levelLabel.getString(context);
    final ladder = summary.mainLadder;
    final reward = ladder.nextReward;

    final rewardText =
        (reward.isChest
                ? AppLocale.ladderChestReward
                : AppLocale.ladderGiftReward)
            .getString(context)
            .replaceAll('{coins}', numberFormat.format(reward.coins));
    final hint =
        (ladder.levelsUntilReward == 1
                ? AppLocale.ladderRewardHintOne
                : AppLocale.ladderRewardHintMany)
            .getString(context)
            .replaceAll('{n}', '${ladder.levelsUntilReward}')
            .replaceAll('{reward}', rewardText);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      semanticLabel: '$levelLabel ${ladder.level}. $hint',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Level medallion. Deliberately the only circular element in
              // the column, so it reads as a rank rather than as a button.
              Container(
                width: AppSize.wellMd,
                height: AppSize.wellMd,
                decoration: const BoxDecoration(
                  color: AppColors.sun,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${ladder.level}',
                  maxLines: 1,
                  style: AppTypography.score(
                    context,
                    size: 22,
                    color: AppColors.onSun,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$levelLabel ${ladder.level}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Flexible so a long streak value or a 135% text
                        // scale shrinks the badge instead of overflowing.
                        Flexible(
                          child: summary.hasStreak
                              ? AppBadge(
                                  icon: Icons.local_fire_department_rounded,
                                  label: '${summary.streakDays}',
                                  background: AppColors.streakSoft,
                                  foreground: AppColors.streakStrong,
                                  compact: true,
                                )
                              : const AppBadge.neutral(
                                  icon: Icons.local_fire_department_rounded,
                                  label: '0',
                                  compact: true,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppProgressBar(
                      value: ladder.rewardProgress,
                      semanticLabel: AppLocale.ladderRewardSemantic.getString(
                        context,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          reward.isChest
                              ? Icons.inventory_2_rounded
                              : Icons.card_giftcard_rounded,
                          size: AppSize.iconXs,
                          color: AppColors.sunStrong,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            hint,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (summary.ladders.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            // Each game climbs its own ladder.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final game in summary.ladders)
                  _LadderChip(ladder: game, levelLabel: levelLabel),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LadderChip extends StatelessWidget {
  const _LadderChip({required this.ladder, required this.levelLabel});

  final GameLadder ladder;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return AppBadge.neutral(
      icon: Icons.stairs_rounded,
      label:
          '${ladder.nameKey.getString(context)} · '
          '$levelLabel ${ladder.level}',
      compact: true,
    );
  }
}
