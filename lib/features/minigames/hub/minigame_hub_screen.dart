import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/features/minigames/hub/widget/minigame_grid.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';

/// Every registered mini-game, one tap away.
///
/// Knows nothing about any particular game: it renders whatever
/// [minigamesProvider] lists and lets each game open itself.
class MinigameHubScreen extends ConsumerWidget {
  const MinigameHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(minigamesProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameHubTitle.getString(context)),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                AppSpacing.xxl,
              ),
              children: [
                Text(
                  AppLocale.minigameHubSubtitle.getString(context),
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                MinigameGrid(games: games),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
