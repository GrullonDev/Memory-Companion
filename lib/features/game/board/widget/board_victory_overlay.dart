import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/confetti_overlay.dart';

/// Full-screen celebration shown when a solo board is completed: a
/// falling-confetti backdrop, an illustrated banner, a run-summary card
/// (score / time / coins) and the play-again / back-to-menu actions.
class BoardVictoryOverlay extends StatelessWidget {
  const BoardVictoryOverlay({
    super.key,
    required this.score,
    required this.elapsedSeconds,
    required this.coinsEarned,
    required this.xpEarned,
    required this.onPlayAgain,
    required this.onExit,
  });

  final int score;
  final int elapsedSeconds;
  final int coinsEarned;
  final int xpEarned;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  String get _timeLabel {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0x99000000)),
        const ConfettiOverlay(),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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
                  const _VictoryIllustration(),
                  const SizedBox(height: 20),
                  Text(
                    AppLocale.completedTitle.getString(context),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    score: score,
                    timeLabel: _timeLabel,
                    coinsEarned: coinsEarned,
                    xpEarned: xpEarned,
                  ),
                  const SizedBox(height: 20),
                  _VictoryActionButton(
                    label: AppLocale.playAgain.getString(context),
                    icon: Icons.refresh_rounded,
                    background: AppColors.primaryFixedDim,
                    foreground: AppColors.onPrimaryFixed,
                    onTap: onPlayAgain,
                  ),
                  const SizedBox(height: 12),
                  _VictoryActionButton(
                    label: AppLocale.backToHome.getString(context),
                    icon: Icons.home_rounded,
                    background: AppColors.secondaryFixed,
                    foreground: AppColors.onSecondaryFixedVariant,
                    onTap: onExit,
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

class _VictoryIllustration extends StatelessWidget {
  const _VictoryIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryFixed, AppColors.primaryFixedDim],
                ),
              ),
            ),
            const Positioned(
              top: 10,
              left: 18,
              child: _Confetto(Color(0xFF00BDFD)),
            ),
            const Positioned(
              top: 16,
              right: 28,
              child: _Confetto(Color(0xFFFFFFFF)),
            ),
            const Positioned(
              bottom: 12,
              left: 40,
              child: _Confetto(Color(0xFF9B7BFF)),
            ),
            const Positioned(
              bottom: 16,
              right: 20,
              child: _Confetto(Color(0xFF4CD97B)),
            ),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: AppColors.primaryFixedDim,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Confetto extends StatelessWidget {
  const _Confetto(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.score,
    required this.timeLabel,
    required this.coinsEarned,
    required this.xpEarned,
  });

  final int score;
  final String timeLabel;
  final int coinsEarned;
  final int xpEarned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
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
          const Divider(height: 1, color: AppColors.outlineVariant),
          _SummaryRow(
            icon: Icons.timer_rounded,
            label: AppLocale.timeLabel.getString(context),
            value: timeLabel,
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          _SummaryRow(
            icon: Icons.monetization_on_rounded,
            label: AppLocale.coinsEarnedLabel.getString(context),
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+$coinsEarned',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onPrimaryFixedVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.outlineVariant),
          _SummaryRow(
            icon: Icons.flash_on_rounded,
            label: 'Experiencia',
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+$xpEarned XP',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.onPrimaryFixed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurface),
            ),
          ),
          valueWidget ??
              Text(
                value ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
        ],
      ),
    );
  }
}

class _VictoryActionButton extends StatelessWidget {
  const _VictoryActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
