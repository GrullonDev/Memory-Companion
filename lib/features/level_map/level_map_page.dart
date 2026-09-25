import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/level_map/controller/level_map_controller.dart';
import 'package:memory_companion/features/level_map/level_map_screen.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:memory_companion/core/localization/app_locale.dart';

/// Connects [levelMapProvider] and the shared wallet to [LevelMapScreen].
///
/// The map is synchronous: progress lives in memory (restored from the
/// local database at startup), so there is no loading state to show and it
/// works offline.
class LevelMapPage extends ConsumerWidget {
  const LevelMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(levelMapProvider);
    final wallet = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LevelMapScreen(
          regionName: AppLocale.levelMapRegionName.getString(context),
          levels: levels,
          coins: wallet.value ?? 0,
          onSelectLevel: (level) {
            if (!level.isPlayable) return;
            // Adaptive boards always deal the player's current level, so a
            // completed node replays at today's difficulty.
            Navigator.of(
              context,
            ).pushNamed(RoutePaths.boardSolo, arguments: levelMapCategory.id);
          },
        ),
      ),
    );
  }
}
