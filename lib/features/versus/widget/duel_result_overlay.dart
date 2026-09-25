import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/confetti_overlay.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';
import 'package:memory_companion/features/versus/model/duel.dart';

/// The end of a duel for one side: both scores once the rival has played,
/// or the player's own while they wait.
class DuelResultOverlay extends StatelessWidget {
  const DuelResultOverlay({
    super.key,
    required this.mine,
    required this.theirs,
    required this.rivalName,
    required this.onExit,
    this.declined = false,
    this.submitFailed = false,
    this.celebrate = false,
  });

  final DuelScore mine;

  /// Null until the rival has played.
  final DuelScore? theirs;
  final String rivalName;
  final VoidCallback onExit;
  final bool declined;
  final bool submitFailed;

  /// Confetti for a win seen as it happens.
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final theirs = this.theirs;
    final comparison = theirs == null ? null : mine.compareTo(theirs);

    final (icon, color, titleKey) = switch (comparison) {
      null when declined => (
        Icons.block_rounded,
        AppColors.onSurfaceVariant,
        AppLocale.duelDeclinedLabel,
      ),
      null => (
        Icons.hourglass_top_rounded,
        AppColors.skyStrong,
        AppLocale.duelsWaitingTitle,
      ),
      > 0 => (
        Icons.emoji_events_rounded,
        AppColors.sunStrong,
        AppLocale.duelWonLabel,
      ),
      < 0 => (
        Icons.sentiment_neutral_rounded,
        AppColors.error,
        AppLocale.duelLostLabel,
      ),
      _ => (
        Icons.handshake_rounded,
        AppColors.skyStrong,
        AppLocale.duelDrawLabel,
      ),
    };

    final String? message = submitFailed
        ? AppLocale.duelSubmitFailed.getString(context)
        : theirs == null && !declined
        ? AppLocale.duelResultSaved
              .getString(context)
              .replaceAll('{name}', rivalName)
        : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tokens.scrimColor),
        if (celebrate &&
            comparison != null &&
            comparison > 0 &&
            tokens.celebrationEffects)
          const ConfettiOverlay(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              margin: const EdgeInsets.symmetric(horizontal: 24),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 64, color: color),
                  const SizedBox(height: 8),
                  Text(
                    titleKey.getString(context),
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    AppLocale.duelVsLabel
                        .getString(context)
                        .replaceAll('{name}', rivalName),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreColumn(
                          label: AppLocale.duelYouLabel.getString(context),
                          score: mine,
                          highlight: comparison != null && comparison > 0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ScoreColumn(
                          label: rivalName,
                          score: theirs,
                          highlight: comparison != null && comparison < 0,
                        ),
                      ),
                    ],
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: submitFailed
                            ? AppColors.error
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AdaptiveButton(
                    label: AppLocale.backToHome.getString(context),
                    icon: Icons.arrow_back_rounded,
                    variant: AdaptiveButtonVariant.secondary,
                    onPressed: onExit,
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

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.highlight,
  });

  final String label;
  final DuelScore? score;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final score = this.score;
    final moves = AppLocale.movesLabel.getString(context).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryFixed
            : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score == null
                ? '—'
                : fill(
                    AppLocale.duelPointsLabel.getString(context),
                    score.score,
                  ),
            maxLines: 1,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (score != null)
            Text(
              '${formatDuration(score.seconds)} · ${score.moves} $moves',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
