import 'package:flutter/material.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';

/// Everything that differs between the two [VisualProfile]s, as one
/// [ThemeExtension].
///
/// Adaptive widgets never branch on the profile themselves; they read the
/// token they need — `ProfileTokens.of(context).buttonMinHeight` — and get
/// the right value for whichever profile is active. Adding a third profile
/// later means adding one constant here, not touching every widget.
///
/// Font size is deliberately **not** a token. The accessible profile raises
/// the app-wide text scale instead (see [minTextScale]), so every `Text` in
/// the product grows — including the ones in screens that were written
/// before this system existed — and nothing is enlarged twice.
@immutable
class ProfileTokens extends ThemeExtension<ProfileTokens> {
  const ProfileTokens({
    required this.profile,
    required this.minTextScale,
    required this.maxTextScale,
    required this.reduceMotion,
    required this.celebrationEffects,
    required this.buttonMinHeight,
    required this.buttonPadding,
    required this.buttonRadius,
    required this.buttonIconSize,
    required this.buttonBorderWidth,
    required this.controlGap,
    required this.cardGridGap,
    required this.cardRadius,
    required this.cardSymbolSize,
    required this.cardBorderWidth,
    required this.cardFaceDownColor,
    required this.onCardFaceDownColor,
    required this.cardFaceUpBorderColor,
    required this.cardMatchedColor,
    required this.flipDuration,
    required this.supportingTextColor,
    required this.outlineColor,
    required this.scrimColor,
  });

  final VisualProfile profile;

  /// Floor and ceiling applied to the OS text-size setting. The accessible
  /// profile raises the floor, so text is large even on a phone left at
  /// default settings, and keeps the same ceiling the layouts were audited
  /// against so nothing overflows.
  final double minTextScale;
  final double maxTextScale;

  /// Forces the platform "reduce motion" flag on. Every widget that already
  /// honours `MediaQuery.disableAnimationsOf` — [Pressable] among them —
  /// calms down without knowing profiles exist.
  final bool reduceMotion;

  /// Confetti, sparkles and other purely decorative celebration.
  final bool celebrationEffects;

  final double buttonMinHeight;
  final EdgeInsets buttonPadding;
  final double buttonRadius;
  final double buttonIconSize;

  /// A visible edge on every button, so its shape never depends on telling
  /// two fills apart.
  final double buttonBorderWidth;

  /// Vertical gap between stacked controls. Wider in the accessible profile
  /// so a slightly-off tap lands on nothing instead of on the wrong button.
  final double controlGap;

  /// Gap between memory cards. *Smaller* in the accessible profile: the
  /// space goes to the cards themselves, which is where the finger lands.
  final double cardGridGap;
  final double cardRadius;
  final double cardSymbolSize;
  final double cardBorderWidth;
  final Color cardFaceDownColor;
  final Color onCardFaceDownColor;
  final Color cardFaceUpBorderColor;
  final Color cardMatchedColor;

  /// Face-down ↔ face-up transition.
  final Duration flipDuration;

  /// Subtitles and secondary copy.
  final Color supportingTextColor;

  /// Borders and dividers that carry meaning (not decorative hairlines).
  final Color outlineColor;

  /// Backdrop behind the pause and victory overlays.
  final Color scrimColor;

  bool get isAccessible => profile.isAccessible;

  /// The fun one: motion, confetti and the full palette.
  static const ProfileTokens vibrant = ProfileTokens(
    profile: VisualProfile.vibrant,
    minTextScale: 1.0,
    maxTextScale: 1.35,
    reduceMotion: false,
    celebrationEffects: true,
    buttonMinHeight: 52,
    buttonPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    buttonRadius: AppRadius.md,
    buttonIconSize: AppSize.iconSm,
    buttonBorderWidth: 0,
    controlGap: AppSpacing.md,
    cardGridGap: AppSpacing.md,
    cardRadius: AppRadius.md,
    cardSymbolSize: 28,
    cardBorderWidth: 3,
    cardFaceDownColor: AppColors.sky,
    onCardFaceDownColor: AppColors.onSky,
    cardFaceUpBorderColor: AppColors.sunDeep,
    cardMatchedColor: AppColors.mintSoft,
    flipDuration: Duration(milliseconds: 200),
    supportingTextColor: AppColors.onSurfaceVariant,
    outlineColor: AppColors.outlineVariant,
    scrimColor: Color(0x99000000),
  );

  /// Large, calm and high-contrast. Every foreground/background pair below
  /// is checked by `test/core/theme/profile_tokens_test.dart`.
  static const ProfileTokens accessible = ProfileTokens(
    profile: VisualProfile.accessible,
    minTextScale: 1.25,
    maxTextScale: 1.35,
    reduceMotion: true,
    celebrationEffects: false,
    buttonMinHeight: 72,
    buttonPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.xxl,
      vertical: AppSpacing.lg,
    ),
    buttonRadius: AppRadius.lg,
    buttonIconSize: AppSize.iconLg,
    buttonBorderWidth: 2,
    controlGap: AppSpacing.lg,
    cardGridGap: AppSpacing.sm,
    cardRadius: AppRadius.sm,
    cardSymbolSize: 40,
    cardBorderWidth: 4,
    // Dark back vs white face: the two states differ in lightness, not just
    // hue, so they stay distinct for colour-blind players and on dim screens.
    cardFaceDownColor: AppColors.inverseSurface,
    onCardFaceDownColor: AppColors.inverseOnSurface,
    cardFaceUpBorderColor: AppColors.onSurface,
    cardMatchedColor: AppColors.mintSoft,
    flipDuration: AppMotion.fast,
    supportingTextColor: AppColors.onSurface,
    outlineColor: AppColors.outline,
    scrimColor: Color(0xE0000000),
  );

  static ProfileTokens forProfile(VisualProfile profile) {
    return switch (profile) {
      VisualProfile.vibrant => vibrant,
      VisualProfile.accessible => accessible,
    };
  }

  /// The active tokens. Falls back to [vibrant] when the theme does not
  /// carry them — e.g. a widget test that pumps a bare `MaterialApp`.
  static ProfileTokens of(BuildContext context) {
    return Theme.of(context).extension<ProfileTokens>() ?? vibrant;
  }

  @override
  ProfileTokens copyWith({VisualProfile? profile}) {
    return profile == null ? this : forProfile(profile);
  }

  /// Profiles are discrete: a half-way point between "large buttons" and
  /// "small buttons" means nothing, so the theme animation swaps tokens at
  /// the midpoint instead of blending them.
  @override
  ProfileTokens lerp(covariant ProfileTokens? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
