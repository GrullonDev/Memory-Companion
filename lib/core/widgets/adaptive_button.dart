import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_shadows.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/widgets/pressable.dart';

/// What a button does, which decides its colour. Never pick colours per
/// call site — pick the intent.
enum AdaptiveButtonVariant {
  /// The one thing the screen wants the player to do.
  primary(AppColors.sun, AppColors.onSun),

  /// An alternative that is still safe and expected.
  secondary(AppColors.skySoft, AppColors.skyStrong),

  /// Present but quiet.
  neutral(AppColors.surfaceContainerLow, AppColors.onSurface),

  /// Leaves or throws something away.
  destructive(AppColors.errorContainer, AppColors.onErrorContainer);

  const AdaptiveButtonVariant(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// Full-width action button that sizes itself from the active
/// [ProfileTokens].
///
/// In the vibrant profile it is a 52px pill with a tinted shadow and a
/// squash on press. In the accessible profile the same call produces a 72px
/// target with a solid outline, a larger icon and no motion — without the
/// call site knowing which profile is on:
///
/// ```dart
/// AdaptiveButton(
///   label: AppLocale.playAgain.getString(context),
///   icon: Icons.refresh_rounded,
///   onPressed: onPlayAgain,
/// )
/// ```
///
/// Text size follows the theme's `titleMedium` and therefore the app-wide
/// text scale, which the accessible profile raises. It is not set here, so
/// it is never enlarged twice.
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AdaptiveButtonVariant.primary,
    this.semanticHint,
  });

  final String label;
  final IconData? icon;

  /// Null renders the button disabled — still visible, still announced.
  final VoidCallback? onPressed;
  final AdaptiveButtonVariant variant;

  /// What happens on activation, when the label alone does not say it
  /// (e.g. "Costs one life").
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final tokens = ProfileTokens.of(context);
    final enabled = onPressed != null;
    final background = enabled ? variant.background : AppColors.disabled;
    final foreground = enabled ? variant.foreground : AppColors.onDisabled;
    final radius = BorderRadius.circular(tokens.buttonRadius);
    final showShadow = enabled && !tokens.isAccessible;

    return Pressable(
      onTap: onPressed,
      enabled: enabled,
      borderRadius: radius,
      semanticHint: semanticHint,
      shadow: showShadow ? AppShadows.tinted(background) : null,
      pressedShadow: showShadow
          ? AppShadows.tinted(background, pressed: true)
          : null,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: tokens.buttonMinHeight),
        padding: tokens.buttonPadding,
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: tokens.buttonBorderWidth > 0
              ? Border.all(color: foreground, width: tokens.buttonBorderWidth)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              // The label already says what the button does.
              ExcludeSemantics(
                child: Icon(
                  icon,
                  color: foreground,
                  size: tokens.buttonIconSize,
                ),
              ),
              SizedBox(width: tokens.controlGap * 0.75),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                // Two lines rather than an ellipsis: at large text a
                // truncated verb ("Volver al…") is worse than a taller button.
                maxLines: tokens.isAccessible ? 2 : 1,
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
    );
  }
}
