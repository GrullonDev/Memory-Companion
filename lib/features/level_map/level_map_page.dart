import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/features/level_map/controller/level_controller.dart';
import 'package:memory_companion/features/level_map/controller/level_map_controller.dart';
import 'package:memory_companion/features/level_map/level_map_screen.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// Connects [LevelMapController] and the shared wallet to [LevelMapScreen].
class LevelMapPage extends ConsumerWidget {
  const LevelMapPage({super.key, required this.regionName});

  final String regionName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(levelMapControllerProvider);
    final wallet = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AsyncValueView(
          value: levels,
          minHeight: double.infinity,
          onRetry: () => ref.invalidate(levelMapControllerProvider),
          data: (context, levels) => LevelMapScreen(
            regionName: regionName,
            levels: levels,
            coins: wallet.value ?? 0,
            onSelectLevel: (level) {
              if (!level.isPlayable) return;
              // Lo lee el tablero al arrancar y también al reintentar,
              // cuando ya no hay navegación de por medio.
              ref.read(selectedLevelProvider.notifier).select(level.number);
              Navigator.of(context).pushNamed(RoutePaths.boardSolo);
            },
          ),
        ),
      ),
    );
  }
}
