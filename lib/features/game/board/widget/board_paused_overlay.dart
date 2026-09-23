import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';

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
    final tokens = ProfileTokens.of(context);
    return Container(
      color: tokens.scrimColor,
      alignment: Alignment.center,
      // Scrolls rather than overflows at the accessible text scale on a
      // short phone.
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: tokens.isAccessible ? 16 : 32,
          ),
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
              _PauseIllustration(decorated: tokens.celebrationEffects),
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                header: true,
                child: Text(
                  AppLocale.pausedTitle.getString(context),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocale.pausedSubtitle.getString(context),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.supportingTextColor,
                ),
              ),
              const SizedBox(height: 24),
              AdaptiveButton(
                label: AppLocale.resumeGame.getString(context),
                icon: Icons.play_arrow_rounded,
                onPressed: onResume,
              ),
              SizedBox(height: tokens.controlGap),
              AdaptiveButton(
                label: AppLocale.settingsLabel.getString(context),
                icon: Icons.settings_rounded,
                variant: AdaptiveButtonVariant.neutral,
                onPressed: onSettings,
              ),
              SizedBox(height: tokens.controlGap),
              AdaptiveButton(
                label: AppLocale.quitMatch.getString(context),
                icon: Icons.close_rounded,
                variant: AdaptiveButtonVariant.destructive,
                onPressed: onQuit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PauseIllustration extends StatelessWidget {
  const _PauseIllustration({required this.decorated});

  /// Scattered confetti pieces. Off in the accessible profile.
  final bool decorated;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
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
              if (decorated) ...const [
                Positioned(
                  top: 10,
                  left: 18,
                  child: _Confetto(Color(0xFFFFE16D)),
                ),
                Positioned(
                  top: 16,
                  right: 28,
                  child: _Confetto(Color(0xFFFFFFFF)),
                ),
                Positioned(
                  bottom: 12,
                  left: 40,
                  child: _Confetto(Color(0xFF9B7BFF)),
                ),
                Positioned(
                  bottom: 16,
                  right: 20,
                  child: _Confetto(Color(0xFF4CD97B)),
                ),
              ],
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
