import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/confetti_overlay.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/ladder/widget/level_reward_card.dart';
import 'package:memory_companion/features/game/board/model/star_rating.dart';

/// Full-screen result shown when a solo board ends: the title, a 1–3 star
/// rating, a motivational line, the coins and XP earned, a run summary and
/// the actions.
///
/// Built to pull the player into the next round: after a win the one
/// prominent action is **Next level**; stats and the menu are quieter
/// neutral buttons below it. Running out of time shows no stars and offers
/// a retry instead.
///
/// Reads [ProfileTokens]: the vibrant profile gets confetti, stars that pop
/// in one by one and a counting-up coin total; the accessible profile gets a
/// calm, opaque backdrop, larger stars that are simply there, and the larger
/// [AdaptiveButton]s. All motion also stops when the OS asks for less.
class BoardVictoryOverlay extends StatelessWidget {
  const BoardVictoryOverlay({
    super.key,
    required this.won,
    required this.stars,
    required this.score,
    required this.moves,
    required this.elapsedSeconds,
    required this.coinsEarned,
    required this.xpEarned,
    required this.onNextLevel,
    required this.onPlayAgain,
    required this.onViewStats,
    required this.onExit,
    this.completedLevel,
    this.levelReward,
  });

  /// The ladder level this win completed. Null on a loss and on the daily
  /// board, which is not part of any ladder.
  final int? completedLevel;

  /// The ladder reward that level earned, if it was a reward step.
  final LevelReward? levelReward;

  /// False when the countdown ran out before the board was cleared.
  final bool won;

  /// 0–[StarRating.maxStars]. See [StarRating].
  final int stars;
  final int score;
  final int moves;
  final int elapsedSeconds;
  final int coinsEarned;
  final int xpEarned;

  /// The primary action after a win.
  final VoidCallback onNextLevel;

  /// The primary action after running out of time.
  final VoidCallback onPlayAgain;
  final VoidCallback onViewStats;
  final VoidCallback onExit;

  String get _timeLabel {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Two lines per star count, picked from the result so consecutive games
  /// do not always say the same thing.
  String get _messageKey {
    if (!won) return AppLocale.resultMessageTimeUp;
    final alternate = (moves + elapsedSeconds).isOdd;
    return switch (stars) {
      >= StarRating.maxStars =>
        alternate
            ? AppLocale.resultMessageStars3b
            : AppLocale.resultMessageStars3a,
      2 =>
        alternate
            ? AppLocale.resultMessageStars2b
            : AppLocale.resultMessageStars2a,
      _ =>
        alternate
            ? AppLocale.resultMessageStars1b
            : AppLocale.resultMessageStars1a,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final title = won ? AppLocale.completedTitle : AppLocale.timeUpTitle;
    final message = _messageKey.getString(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tokens.scrimColor),
        if (won && tokens.celebrationEffects) const ConfettiOverlay(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: tokens.isAccessible
                    ? AppSpacing.lg
                    : AppSpacing.xxxl,
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.xxl,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
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
                  // Title and message are announced together as soon as the
                  // overlay appears, so a screen-reader user learns how the
                  // match ended without hunting for it.
                  Semantics(
                    liveRegion: true,
                    header: true,
                    label: '${title.getString(context)}. $message',
                    excludeSemantics: true,
                    child: Text(
                      title.getString(context),
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: won ? AppColors.primary : AppColors.warning,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (won && completedLevel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppLocale.levelCompletedLabel
                          .getString(context)
                          .replaceAll('{level}', '$completedLevel'),
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: tokens.supportingTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (won) ...[
                    const SizedBox(height: AppSpacing.lg),
                    StarRatingWidget(stars: stars),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  ExcludeSemantics(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: tokens.supportingTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _RewardBanner(coins: coinsEarned, xp: xpEarned),
                  if (won && levelReward != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    LevelRewardCard(reward: levelReward!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _SummaryCard(
                    score: score,
                    timeLabel: _timeLabel,
                    moves: moves,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (won)
                    AdaptiveButton(
                      label: AppLocale.nextLevelLabel.getString(context),
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onNextLevel,
                    )
                  else
                    AdaptiveButton(
                      label: AppLocale.playAgain.getString(context),
                      icon: Icons.refresh_rounded,
                      onPressed: onPlayAgain,
                    ),
                  SizedBox(height: tokens.controlGap),
                  AdaptiveButton(
                    label: AppLocale.viewStatsLabel.getString(context),
                    icon: Icons.bar_chart_rounded,
                    variant: AdaptiveButtonVariant.neutral,
                    onPressed: onViewStats,
                  ),
                  SizedBox(height: tokens.controlGap),
                  AdaptiveButton(
                    label: AppLocale.backToHome.getString(context),
                    icon: Icons.home_rounded,
                    variant: AdaptiveButtonVariant.neutral,
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

/// A row of [StarRating.maxStars] stars, [stars] of them filled.
///
/// Earned and missing stars differ in shape (filled vs outlined), not only
/// colour, so the result reads the same for colour-blind players. In the
/// vibrant profile the middle star sits higher and the earned ones pop in
/// one after another; in the accessible profile all three are the same,
/// larger size and appear at once.
class StarRatingWidget extends StatelessWidget {
  const StarRatingWidget({super.key, required this.stars});

  final int stars;

  static const _popStagger = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final earned = stars.clamp(0, StarRating.maxStars);

    return Semantics(
      label: AppLocale.starsEarnedSemantics
          .getString(context)
          .replaceAll('{n}', '$earned'),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < StarRating.maxStars; i++)
            Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : AppSpacing.xs,
                // Arcade-style arc: the middle star is lifted.
                bottom: !tokens.isAccessible && i == 1 ? AppSpacing.md : 0,
              ),
              child: _Star(
                filled: i < earned,
                size: tokens.isAccessible
                    ? 56
                    : (i == 1 ? 60 : 48),
                delay: animate && i < earned ? _popStagger * i : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({required this.filled, required this.size, this.delay});

  final bool filled;
  final double size;

  /// When set, the star pops in after this long. Null draws it at rest.
  final Duration? delay;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final icon = Icon(
      filled ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: filled ? AppColors.sunDeep : tokens.outlineColor,
      shadows: filled && !tokens.isAccessible
          ? const [
              Shadow(
                color: Color(0x66E0A400),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ]
          : null,
    );

    final delay = this.delay;
    if (delay == null) return icon;

    // One tween per star with the stagger folded into its curve, so there
    // is no timer to cancel if the overlay goes away mid-animation.
    final total = delay + AppMotion.celebrate;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.bounce),
      child: icon,
      builder: (context, t, child) => Transform.scale(
        scale: t,
        child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
      ),
    );
  }
}

/// The coins and XP earned, as two bright pills. The coin total counts up
/// from zero unless motion is reduced.
class _RewardBanner extends StatelessWidget {
  const _RewardBanner({required this.coins, required this.xp});

  final int coins;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final animate = !MediaQuery.disableAnimationsOf(context);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (coins > 0)
          _RewardPill(
            icon: Icons.monetization_on_rounded,
            iconColor: AppColors.sunDeep,
            background: AppColors.sunSoft,
            foreground: AppColors.onSun,
            semanticLabel:
                '${AppLocale.coinsEarnedLabel.getString(context)}, +$coins',
            child: animate
                ? TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: coins),
                    duration: AppMotion.celebrate * 2,
                    curve: AppMotion.enter,
                    builder: (context, value, _) => _PillText('+$value'),
                  )
                : _PillText('+$coins'),
          ),
        _RewardPill(
          icon: Icons.flash_on_rounded,
          iconColor: AppColors.violetStrong,
          background: AppColors.violetSoft,
          foreground: AppColors.onViolet,
          semanticLabel:
              '${AppLocale.experienceLabel.getString(context)}, +$xp XP',
          child: _PillText('+$xp XP'),
        ),
      ],
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.foreground,
    required this.semanticLabel,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color foreground;

  /// Read once, with the final value — never the numbers counting up.
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: tokens.isAccessible
              ? Border.all(color: foreground, width: tokens.buttonBorderWidth)
              : null,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foreground),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: tokens.buttonIconSize),
              const SizedBox(width: AppSpacing.xs),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PillText extends StatelessWidget {
  const _PillText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: DefaultTextStyle.of(context).style.color,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.score,
    required this.timeLabel,
    required this.moves,
  });

  final int score;
  final String timeLabel;
  final int moves;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final divider = Divider(height: 1, color: tokens.outlineColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: const Border(
          top: BorderSide(color: AppColors.secondaryContainer, width: 3),
        ),
      ),
      child: Column(
        children: [
          _SummaryRow(
            icon: Icons.flag_rounded,
            label: AppLocale.scoreLabel.getString(context),
            value: _thousands(score),
          ),
          divider,
          _SummaryRow(
            icon: Icons.timer_rounded,
            label: AppLocale.timeLabel.getString(context),
            value: timeLabel,
          ),
          divider,
          _SummaryRow(
            icon: Icons.touch_app_rounded,
            label: AppLocale.movesLabel.getString(context),
            value: '$moves',
          ),
        ],
      ),
    );
  }

  String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

/// One label/value line. Merged into a single semantics node so a screen
/// reader says "Score, 1,250" instead of two unrelated fragments.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                color: AppColors.secondary,
                size: AppSize.iconSm,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
