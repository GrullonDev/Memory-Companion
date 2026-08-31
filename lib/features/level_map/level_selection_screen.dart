import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/features/level_map/controller/level_controller.dart';
import 'package:memory_companion/features/level_map/model/level.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// Level selection screen showing all available levels Candy Crush style
class LevelSelectionScreen extends ConsumerWidget {
  const LevelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(userLevelsProvider);
    final walletAsync = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(
                'Niveles',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded,
                            color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        walletAsync.maybeWhen(
                          data: (coins) => Text(
                            '$coins',
                            style: Theme.of(context)
                                .textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          orElse: () => const Text('--'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Levels grid
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: AsyncValueView<List<GameLevel>>(
                value: levelsAsync,
                onRetry: () => ref.invalidate(userLevelsProvider),
                data: (context, levels) {
                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final level = levels[index];
                        return _LevelCard(level: level);
                      },
                      childCount: levels.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends ConsumerWidget {
  const _LevelCard({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLocked = !level.isUnlocked && !level.isCompleted;
    final isCompleted = level.isCompleted;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              // Handle level selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Nivel ${level.levelNumber} - Dificultad: ${level.difficulty}⭐'),
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          gradient: isLocked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.outlineVariant.withOpacity(0.3),
                    AppColors.outlineVariant.withOpacity(0.1),
                  ],
                )
              : isCompleted
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryFixed,
                        AppColors.primaryFixedDim,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondaryFixed,
                        AppColors.secondaryFixedDim,
                      ],
                    ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? AppColors.primary : AppColors.secondary,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isLocked
                  ? Colors.transparent
                  : (isCompleted ? AppColors.primary : AppColors.secondary)
                      .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Level number
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${level.levelNumber}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: isLocked
                          ? AppColors.outlineVariant
                          : isCompleted
                              ? AppColors.onPrimaryFixed
                              : AppColors.onSecondaryFixed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < level.difficulty; i++)
                        Text(
                          '⭐',
                          style: TextStyle(
                            fontSize: 12,
                            color: isLocked
                                ? AppColors.outlineVariant.withOpacity(0.5)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Lock icon for locked levels
            if (isLocked)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: AppColors.background,
                    size: 14,
                  ),
                ),
              ),

            // Check mark for completed levels
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.onPrimaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primaryFixed,
                    size: 14,
                  ),
                ),
              ),

            // Best score badge
            if (level.bestScore > 0)
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🏆 ${level.bestScore}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
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
