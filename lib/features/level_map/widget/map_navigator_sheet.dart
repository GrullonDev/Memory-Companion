import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_progress_bar.dart';
import 'package:memory_companion/features/level_map/controller/map_navigator_controller.dart';

/// What the player picked in the map navigator.
enum MapNavigatorAction { goToMyLevel, playCurrent }

/// The map navigator: where the player stands in the region, the reward
/// track, and the two things worth doing from here.
class MapNavigatorSheet extends StatelessWidget {
  const MapNavigatorSheet({
    super.key,
    required this.regionName,
    required this.progress,
  });

  final String regionName;
  final MapProgress progress;

  static Future<MapNavigatorAction?> show(
    BuildContext context, {
    required String regionName,
    required MapProgress progress,
  }) {
    return showModalBottomSheet<MapNavigatorAction>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      showDragHandle: true,
      // Sized by its content, and scrolls on short screens or large text.
      isScrollControlled: true,
      builder: (_) =>
          MapNavigatorSheet(regionName: regionName, progress: progress),
    );
  }

  String _fill(String template, Map<String, Object> values) {
    var out = template;
    values.forEach((key, value) => out = out.replaceAll('{$key}', '$value'));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reward = progress.nextReward;

    return SafeArea(
      child: SingleChildScrollView(
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
            Row(
              children: [
                const Icon(
                  Icons.forest_rounded,
                  size: 36,
                  color: AppColors.mintDeep,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        regionName,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_fill(AppLocale.mapCurrentLevelLabel.getString(context), {'n': progress.currentLevel})}'
                        ' · '
                        '${_fill(AppLocale.mapLevelsCleared.getString(context), {'n': progress.levelsCleared})}',
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
            _RewardTrack(
              isChest: reward.isChest,
              title: _fill(
                (reward.isChest
                        ? AppLocale.mapNextChest
                        : AppLocale.mapNextGift)
                    .getString(context),
                {'coins': reward.coins, 'level': reward.level},
              ),
              caption: progress.rewardWithinReach
                  ? AppLocale.mapRewardOneAway.getString(context)
                  : _fill(AppLocale.mapLevelsToReward.getString(context), {
                      'n': progress.levelsToReward,
                    }),
              progress: progress.rewardProgress,
              highlight: progress.rewardWithinReach,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(MapNavigatorAction.playCurrent),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                _fill(AppLocale.mapPlayLevel.getString(context), {
                  'n': progress.currentLevel,
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(MapNavigatorAction.goToMyLevel),
              icon: const Icon(Icons.my_location_rounded),
              label: Text(AppLocale.mapGoToMyLevel.getString(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardTrack extends StatelessWidget {
  const _RewardTrack({
    required this.isChest,
    required this.title,
    required this.caption,
    required this.progress,
    required this.highlight,
  });

  final bool isChest;
  final String title;
  final String caption;
  final double progress;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: highlight ? AppColors.sun : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isChest ? Icons.inventory_2_rounded : Icons.card_giftcard_rounded,
            size: 36,
            color: highlight ? AppColors.onSun : AppColors.sunDeep,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: highlight ? AppColors.onSun : null,
                  ),
                ),
                const SizedBox(height: 6),
                AppProgressBar(value: progress),
                const SizedBox(height: 4),
                Text(
                  caption,
                  style: textTheme.bodySmall?.copyWith(
                    color: highlight
                        ? AppColors.onSun
                        : AppColors.onSurfaceVariant,
                    fontWeight: highlight ? FontWeight.w700 : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
