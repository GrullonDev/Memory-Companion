import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/pinned_footer_layout.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_intro.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/pattern/controller/pattern_controller.dart';
import 'package:memory_companion/features/minigames/modules/pattern/model/pattern_state.dart';
import 'package:memory_companion/features/minigames/modules/pattern/pattern_game_module.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

class PatternScreen extends ConsumerWidget {
  const PatternScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patternControllerProvider);
    final controller = ref.read(patternControllerProvider.notifier);

    final body = switch (state.phase) {
      PatternPhase.intro => MinigameIntro(
        icon: Icons.apps_rounded,
        color: AppColors.mintStrong,
        level: state.level,
        text: AppLocale.patternIntro.getString(context),
        onStart: controller.start,
      ),
      PatternPhase.finished => PinnedFooterLayout(
        children: [
          MinigameResultView(
            game: const PatternGameModule(),
            won: state.won,
            headline: '${state.found.length}/${state.lit.length}',
            caption: AppLocale.patternFoundLabel.getString(context),
            message:
                (state.won
                        ? AppLocale.patternResultWon
                        : AppLocale.patternResultLost)
                    .getString(context),
            primaryLabel:
                (state.won ? AppLocale.nextLevelLabel : AppLocale.playAgain)
                    .getString(context),
            onPrimary: state.won ? controller.nextLevel : controller.retry,
          ),
        ],
      ),
      _ => _Board(state: state, controller: controller),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigamePatternTitle.getString(context)),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state, required this.controller});

  final PatternState state;
  final PatternController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = state.difficulty.gridSize;
    final showing = state.phase == PatternPhase.showing;

    return PinnedFooterLayout(
      footer: showing
          ? AdaptiveButton(
              label: AppLocale.wordsReadyLabel.getString(context),
              icon: Icons.check_rounded,
              onPressed: controller.hide,
            )
          : null,
      children: [
        Text(
          fill(AppLocale.minigameLevelLabel.getString(context), state.level),
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          showing
              ? AppLocale.patternMemorizeLabel.getString(context)
              : fill(
                  AppLocale.patternTapLabel.getString(context),
                  state.lit.length - state.found.length,
                ).replaceAll(
                  '{total}',
                  '${state.difficulty.allowedErrors - state.errors}',
                ),
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
              child: Column(
                children: [
                  for (var row = 0; row < size; row++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < size; col++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: _Cell(
                                  index: row * size + col,
                                  state: state,
                                  onTap: controller.tap,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.index, required this.state, required this.onTap});

  final int index;
  final PatternState state;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final showing = state.phase == PatternPhase.showing;
    final color = showing && state.lit.contains(index)
        ? AppColors.mint
        : state.found.contains(index)
        ? AppColors.mintStrong
        : state.wrong.contains(index)
        ? AppColors.error
        : AppColors.surfaceContainerHigh;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => onTap(index),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}
