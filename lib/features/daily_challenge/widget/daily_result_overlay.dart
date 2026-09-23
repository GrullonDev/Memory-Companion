import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/confetti_overlay.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_result.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_streak.dart';
import 'package:memory_companion/features/daily_challenge/share/daily_share.dart';

/// Result of the daily challenge: the numbers, the emoji grid exactly as it
/// will be shared, the streak, and a single prominent Share button.
///
/// There is no "play again": the board is the same for everyone today, so a
/// second attempt would be played from memory. The grid is shown on screen
/// so players see what they are about to post before they post it.
class DailyResultOverlay extends StatelessWidget {
  const DailyResultOverlay({
    super.key,
    required this.result,
    required this.streak,
    required this.celebrate,
    required this.onExit,
  });

  final DailyResult result;
  final DailyStreak streak;

  /// Confetti on the moment of completion only, not when reopening a
  /// result finished earlier in the day.
  final bool celebrate;

  final VoidCallback onExit;

  String _shareText(BuildContext context) {
    return DailyShareText.build(
      result: result,
      streak: streak.current,
      strings: DailyShareStrings(
        challenge: AppLocale.dailyChallengeNumberLabel.getString(context),
        moves: AppLocale.dailyMovesUnit.getString(context),
        streakDays: AppLocale.streakDaysLabel.getString(context),
        callToAction: AppLocale.dailyShareCta.getString(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tokens.scrimColor),
        if (celebrate && tokens.celebrationEffects) const ConfettiOverlay(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              margin: EdgeInsets.symmetric(
                horizontal: tokens.isAccessible ? 16 : 24,
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppLocale.dailyChallengeNumberLabel.getString(context)}'
                    ' #${result.number}',
                    style: textTheme.labelLarge?.copyWith(
                      color: tokens.supportingTextColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    liveRegion: true,
                    header: true,
                    child: Text(
                      AppLocale.dailyResultTitle.getString(context),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StatsRow(result: result, streak: streak),
                  const SizedBox(height: 20),
                  _EmojiGrid(result: result),
                  const SizedBox(height: 8),
                  Text(
                    AppLocale.dailyGridLegend.getString(context),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: tokens.supportingTextColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Builder: the button's own context anchors the iPad
                  // share popover.
                  Builder(
                    builder: (buttonContext) => AdaptiveButton(
                      label: AppLocale.dailyShareButton.getString(context),
                      icon: Icons.ios_share_rounded,
                      onPressed: () => shareDailyResult(
                        _shareText(context),
                        origin: buttonContext,
                      ),
                    ),
                  ),
                  SizedBox(height: tokens.controlGap),
                  AdaptiveButton(
                    label: AppLocale.backToHome.getString(context),
                    icon: Icons.home_rounded,
                    variant: AdaptiveButtonVariant.secondary,
                    onPressed: onExit,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocale.dailyComeBackTomorrow
                        .getString(context)
                        .replaceAll('{n}', '${result.number + 1}'),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: tokens.supportingTextColor,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.result, required this.streak});

  final DailyResult result;
  final DailyStreak streak;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _Stat(
          icon: Icons.timer_rounded,
          label: AppLocale.timeLabel.getString(context),
          value: DailyShareText.formatDuration(result.elapsedSeconds),
        ),
        _Stat(
          icon: Icons.swap_horiz_rounded,
          label: AppLocale.movesLabel.getString(context),
          value: '${result.moves}',
        ),
        _Stat(
          icon: Icons.flag_rounded,
          label: AppLocale.scoreLabel.getString(context),
          value: '${result.score}',
        ),
        _Stat(
          icon: Icons.local_fire_department_rounded,
          label: AppLocale.streakDaysLabel.getString(context),
          value: '${streak.current}',
          caption:
              '${AppLocale.bestStreakLabel.getString(context)}: '
              '${streak.longest}',
        ),
      ],
    );
  }
}

/// One figure with its label. Merged so a screen reader reads "Time, 42s".
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Icon(icon, color: AppColors.secondary, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: textTheme.labelSmall?.copyWith(
                color: tokens.supportingTextColor,
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: tokens.supportingTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The share grid, drawn with the same emoji that will be posted.
class _EmojiGrid extends StatelessWidget {
  const _EmojiGrid({required this.result});

  final DailyResult result;

  @override
  Widget build(BuildContext context) {
    // Decorative: its meaning is in the stats and the legend.
    return ExcludeSemantics(
      child: Column(
        children: [
          for (final row in result.emojiRows)
            Text(row, style: const TextStyle(fontSize: 28, height: 1.25)),
        ],
      ),
    );
  }
}
