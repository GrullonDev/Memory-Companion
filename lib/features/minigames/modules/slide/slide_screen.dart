import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/pinned_footer_layout.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_intro.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/slide/controller/slide_controller.dart';
import 'package:memory_companion/features/minigames/modules/slide/model/slide_state.dart';
import 'package:memory_companion/features/minigames/modules/slide/slide_game_module.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

class SlideScreen extends ConsumerWidget {
  const SlideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(slideControllerProvider);
    final controller = ref.read(slideControllerProvider.notifier);

    final body = switch (state.phase) {
      SlidePhase.intro => MinigameIntro(
        icon: Icons.view_module_rounded,
        color: AppColors.skyStrong,
        level: state.level,
        text: AppLocale.slideIntro.getString(context),
        onStart: controller.start,
      ),
      SlidePhase.finished => PinnedFooterLayout(
        children: [
          MinigameResultView(
            game: const SlideGameModule(),
            won: true,
            headline: '${state.moves}',
            caption: AppLocale.slideMovesLabel.getString(context),
            message: AppLocale.slideResultWon.getString(context),
            primaryLabel: AppLocale.nextLevelLabel.getString(context),
            onPrimary: controller.nextLevel,
          ),
        ],
      ),
      SlidePhase.playing => _Board(state: state, onTap: controller.tap),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameSlideTitle.getString(context)),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state, required this.onTap});

  final SlideState state;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final board = state.board!;
    final size = board.size;

    return PinnedFooterLayout(
      children: [
        Text(
          fill(AppLocale.minigameLevelLabel.getString(context), state.level),
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '${state.moves} ${AppLocale.slideMovesLabel.getString(context)}',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cell = constraints.maxWidth / size;
                  // Positioned by tile number, so a slide animates.
                  return Stack(
                    children: [
                      for (var i = 0; i < board.tiles.length; i++)
                        if (board.tiles[i] != 0)
                          AnimatedPositioned(
                            key: ValueKey(board.tiles[i]),
                            duration: AppMotion.fast,
                            left: (i % size) * cell,
                            top: (i ~/ size) * cell,
                            width: cell,
                            height: cell,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: _Tile(
                                number: board.tiles[i],
                                inPlace: board.tiles[i] == i + 1,
                                onTap: () => onTap(i),
                              ),
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.number,
    required this.inPlace,
    required this.onTap,
  });

  final int number;
  final bool inPlace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$number',
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: inPlace ? AppColors.skySoft : AppColors.sky,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Text(
                  '$number',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: inPlace ? AppColors.skyStrong : AppColors.onSky,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
