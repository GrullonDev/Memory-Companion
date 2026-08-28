import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

/// Pause-state overlay for the memory board: an illustrated banner, a
/// title/subtitle pair, and three stacked actions (resume, settings, quit).
class BoardPausedOverlay extends StatelessWidget {
  const BoardPausedOverlay({
    super.key,
    required this.onResume,
    required this.onSettings,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onSettings;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x99000000),
      alignment: Alignment.center,
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
            const _PauseIllustration(),
            const SizedBox(height: 20),
            Text(
              AppLocale.pausedTitle.getString(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocale.pausedSubtitle.getString(context),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _PauseActionButton(
              label: AppLocale.resumeGame.getString(context),
              icon: Icons.play_arrow_rounded,
              background: AppColors.primaryFixedDim,
              foreground: AppColors.onPrimaryFixed,
              onTap: onResume,
            ),
            const SizedBox(height: 12),
            _PauseActionButton(
              label: AppLocale.settingsLabel.getString(context),
              icon: Icons.settings_rounded,
              background: AppColors.surfaceContainerLow,
              foreground: AppColors.onSurface,
              borderColor: AppColors.outlineVariant,
              onTap: onSettings,
            ),
            const SizedBox(height: 12),
            _PauseActionButton(
              label: AppLocale.quitMatch.getString(context),
              icon: Icons.close_rounded,
              background: AppColors.errorContainer,
              foreground: AppColors.onErrorContainer,
              onTap: onQuit,
            ),
          ],
        ),
      ),
    );
  }
}

class _PauseIllustration extends StatelessWidget {
  const _PauseIllustration();

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
                  colors: [
                    AppColors.secondaryFixed,
                    AppColors.secondaryContainer,
                  ],
                ),
              ),
            ),
            const Positioned(top: 10, left: 18, child: _Confetto(Color(0xFFFFE16D))),
            const Positioned(top: 16, right: 28, child: _Confetto(Color(0xFFFFFFFF))),
            const Positioned(bottom: 12, left: 40, child: _Confetto(Color(0xFF9B7BFF))),
            const Positioned(bottom: 16, right: 20, child: _Confetto(Color(0xFF4CD97B))),
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
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
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _PauseActionButton extends StatelessWidget {
  const _PauseActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: background,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!),
        ),
        child: InkWell(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
