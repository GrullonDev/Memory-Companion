import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/core/widgets/avatar_picker.dart';
import 'package:memory_companion/features/profile/controller/profile_controller.dart';
import 'package:memory_companion/features/profile/model/profile_data.dart';
import 'package:memory_companion/features/profile/widget/achievements_grid.dart';
import 'package:memory_companion/features/profile/widget/match_history_tile.dart';
import 'package:memory_companion/features/profile/widget/next_level_card.dart';
import 'package:memory_companion/features/profile/widget/performance_chart_card.dart';
import 'package:memory_companion/features/profile/widget/profile_header.dart';
import 'package:memory_companion/features/profile/widget/profile_stat_grid.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _openAvatarSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (sheetContext, ref, _) {
            final profile = ref.watch(profileControllerProvider).value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocale.chooseAvatarTitle.getString(sheetContext),
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  AvatarPicker(
                    seed: profile?.avatarSeed ?? 0,
                    onRandomize: () => ref
                        .read(profileControllerProvider.notifier)
                        .randomizeAvatar(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocale.avatarUpdatedMessage.getString(context),
                            ),
                          ),
                        );
                      },
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.onSurface,
                  ),
                ),
                Expanded(
                  child: Text(
                    AppLocale.profileTitle.getString(context),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 8),
            AsyncValueView(
              value: profile,
              onRetry: () => ref.invalidate(profileControllerProvider),
              data: (context, ProfileData data) => Column(
                children: [
                  ProfileHeader(
                    name: data.name,
                    rank: data.rank,
                    level: data.level,
                    onEditAvatar: () => _openAvatarSheet(context, ref),
                  ),
                  const SizedBox(height: 24),
                  NextLevelCard(
                    currentXp: data.currentXp,
                    targetXp: data.targetXp,
                  ),
                  const SizedBox(height: 16),
                  ProfileStatGrid(
                    gamesWon: data.gamesWon,
                    totalMoves: data.totalMoves,
                    bestStreak: data.bestStreak,
                    totalCoins: data.totalCoins,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocale.achievementsTitle.getString(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AchievementsGrid(achievements: data.achievements),
                  const SizedBox(height: 24),
                  PerformanceChartCard(
                    points: [
                      for (final point in data.performancePoints)
                        (label: point.label, value: point.value),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocale.matchHistoryTitle.getString(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final match in data.matches) ...[
                    MatchHistoryTile(match: match),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
