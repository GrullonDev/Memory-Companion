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
import 'package:memory_companion/features/minigames/modules/sequence/controller/sequence_controller.dart';
import 'package:memory_companion/features/minigames/modules/sequence/model/sequence_state.dart';
import 'package:memory_companion/features/minigames/modules/sequence/sequence_game_module.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';

/// Pad colours, as many as the largest board. Distinct in hue so no two
/// neighbours can be mistaken for each other.
const _padColors = [
  AppColors.sun,
  AppColors.sky,
  AppColors.mint,
  AppColors.violet,
  AppColors.streak,
  Color(0xFFE57373),
  Color(0xFF4DB6AC),
  Color(0xFF9575CD),
  Color(0xFFA1887F),
];

class SequenceScreen extends ConsumerWidget {
  const SequenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sequenceControllerProvider);
    final controller = ref.read(sequenceControllerProvider.notifier);

    final body = switch (state.phase) {
      SequencePhase.intro => MinigameIntro(
        icon: Icons.touch_app_rounded,
        color: AppColors.violetStrong,
        level: state.level,
        text: AppLocale.sequenceIntro.getString(context),
        onStart: controller.start,
      ),
      SequencePhase.finished => PinnedFooterLayout(
        children: [
          MinigameResultView(
            game: const SequenceGameModule(),
            won: state.won,
            headline: '${state.bestLength}',
            caption: AppLocale.sequenceBestLabel.getString(context),
            message: fill(
              (state.won
                      ? AppLocale.sequenceResultWon
                      : AppLocale.sequenceResultLost)
                  .getString(context),
              state.difficulty.targetLength,
            ),
            primaryLabel:
                (state.won ? AppLocale.nextLevelLabel : AppLocale.playAgain)
                    .getString(context),
            onPrimary: state.won ? controller.nextLevel : controller.retry,
          ),
        ],
      ),
      _ => _Board(state: state, onTap: controller.tap),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.minigameSequenceTitle.getString(context)),
      ),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.state, required this.onTap});

  final SequenceState state;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pads = state.difficulty.pads;
    final columns = pads == 4 ? 2 : 3;
    final (status, statusColor) = switch (state.phase) {
      SequencePhase.showing => (
        AppLocale.sequenceWatchLabel.getString(context),
        AppColors.onSurfaceVariant,
      ),
      SequencePhase.input => (
        AppLocale.sequenceYourTurnLabel.getString(context),
        AppColors.violetStrong,
      ),
      _ =>
        state.lastCorrect
            ? (
                AppLocale.minigameCorrectLabel.getString(context),
                AppColors.mintStrong,
              )
            : (
                AppLocale.minigameWrongLabel.getString(context),
                AppColors.error,
              ),
    };

    return PinnedFooterLayout(
      children: [
        Text(
          fill(AppLocale.minigameLevelLabel.getString(context), state.level),
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          fill(
            AppLocale.sequenceLengthLabel.getString(context),
            state.length,
          ).replaceAll('{total}', '${state.difficulty.targetLength}'),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          status,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(color: statusColor),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AspectRatio(
              aspectRatio: columns / (pads / columns).ceil(),
              child: Column(
                children: [
                  for (var row = 0; row * columns < pads; row++)
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < columns; col++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                child: _Pad(
                                  index: row * columns + col,
                                  lit: state.lit == row * columns + col,
                                  enabled: state.phase == SequencePhase.input,
                                  onTap: onTap,
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

class _Pad extends StatelessWidget {
  const _Pad({
    required this.index,
    required this.lit,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final bool lit;
  final bool enabled;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final color = _padColors[index % _padColors.length];
    return Semantics(
      button: true,
      enabled: enabled,
      label: '${index + 1}',
      child: GestureDetector(
        onTapDown: enabled ? (_) => onTap(index) : null,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          decoration: BoxDecoration(
            color: lit ? color : color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: lit ? AppColors.onSurface : Colors.transparent,
              width: 3,
            ),
            boxShadow: lit
                ? [BoxShadow(color: color, blurRadius: 18, spreadRadius: 2)]
                : null,
          ),
        ),
      ),
    );
  }
}
