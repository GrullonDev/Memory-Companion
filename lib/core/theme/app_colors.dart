import 'package:flutter/material.dart';

/// Color tokens for the "Vibrant Kinetic" design system.
///
/// Structure:
///  * **Neutrals** — one single slate ramp used for every surface and every
///    piece of text. Never hand-pick a grey outside this ramp.
///  * **Brand ramps** — four families (sun / sky / mint / violet) plus a
///    streak accent. Each family exposes the same four roles:
///      `X`        the saturated fill used on large surfaces
///      `onX`      text/icon colour placed **on** that fill (>= 4.5:1)
///      `xSoft`    pale tint for icon wells and section backgrounds on white
///      `xStrong`  the same hue darkened for text/icons **on white** (>= 4.5:1)
///      `xDeep`    pressed state and the 3D bottom edge of a raised surface
///  * **Material 3 [ColorScheme]** — [lightScheme], wired into `AppTheme`.
///
/// Every foreground/background pair documented here was contrast-checked
/// against WCAG 2.1 AA (4.5:1 for body text, 3:1 for large text and icons).
abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Neutrals — a single cool-slate ramp
  // ---------------------------------------------------------------------
  static const Color surface = Color(0xFFF7F8FC);
  static const Color surfaceDim = Color(0xFFE6EAF2);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F4F9);
  static const Color surfaceContainer = Color(0xFFEBEEF5);
  static const Color surfaceContainerHigh = Color(0xFFE3E7F0);
  static const Color surfaceContainerHighest = Color(0xFFDAE0EC);

  /// 15.9:1 on white. Titles, scores, anything that must be read instantly.
  static const Color onSurface = Color(0xFF101828);

  /// 7.6:1 on [surface]. Subtitles and supporting copy.
  static const Color onSurfaceVariant = Color(0xFF4A5568);

  /// 5.3:1 on white — safe for 12px metadata, unlike the previous olive tone.
  static const Color outline = Color(0xFF667085);

  /// Decorative hairlines and dividers only. Never used for text.
  static const Color outlineVariant = Color(0xFFD3D8E3);

  static const Color inverseSurface = Color(0xFF1B2434);
  static const Color inverseOnSurface = Color(0xFFEEF2F9);

  static const Color background = surface;
  static const Color onBackground = onSurface;
  static const Color surfaceVariant = surfaceContainerHighest;

  // ---------------------------------------------------------------------
  // Brand ramp — SUN (yellow): the primary action, XP and coins
  // ---------------------------------------------------------------------
  /// 8.5:1 against [onSun]. The single loudest colour in the app.
  static const Color sun = Color(0xFFFFC531);
  static const Color onSun = Color(0xFF3D2C00);
  static const Color sunSoft = Color(0xFFFFF4D6);
  static const Color sunStrong = Color(0xFF8A6100);
  static const Color sunDeep = Color(0xFFE0A400);

  // ---------------------------------------------------------------------
  // Brand ramp — SKY (cyan): multiplayer and anything social
  // ---------------------------------------------------------------------
  /// 6.2:1 against [onSky].
  static const Color sky = Color(0xFF35C4F0);
  static const Color onSky = Color(0xFF05384A);
  static const Color skySoft = Color(0xFFDDF3FC);
  static const Color skyStrong = Color(0xFF0B5E7A);
  static const Color skyDeep = Color(0xFF17A5D6);

  // ---------------------------------------------------------------------
  // Brand ramp — MINT (green): the daily challenge, progress and success
  // ---------------------------------------------------------------------
  /// 6.6:1 against [onMint].
  static const Color mint = Color(0xFF3DD07F);
  static const Color onMint = Color(0xFF06381E);
  static const Color mintSoft = Color(0xFFDCF6E7);
  static const Color mintStrong = Color(0xFF0E7A44);
  static const Color mintDeep = Color(0xFF23B268);

  // ---------------------------------------------------------------------
  // Brand ramp — VIOLET (purple): shop, cosmetics and unlockables
  // ---------------------------------------------------------------------
  /// 5.6:1 against [onViolet].
  static const Color violet = Color(0xFFA78BFA);
  static const Color onViolet = Color(0xFF2E1065);
  static const Color violetSoft = Color(0xFFEBE4FE);
  static const Color violetStrong = Color(0xFF5B34C7);
  static const Color violetDeep = Color(0xFF8B69F2);

  // ---------------------------------------------------------------------
  // Accent — STREAK (orange): urgency, fire, "don't lose it today"
  // ---------------------------------------------------------------------
  static const Color streak = Color(0xFFFF7A3D);
  static const Color onStreak = Color(0xFF4A1B00);
  static const Color streakSoft = Color(0xFFFFE8DA);
  static const Color streakStrong = Color(0xFFB44100);
  static const Color streakDeep = Color(0xFFE85F1F);

  // ---------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------
  static const Color success = mintStrong;
  static const Color successContainer = mintSoft;
  static const Color warning = streakStrong;
  static const Color warningContainer = streakSoft;
  static const Color error = Color(0xFFC5221F);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFE4E1);
  static const Color onErrorContainer = Color(0xFF7A0F0D);

  /// Neutral fill + text for a control that is present but not available.
  static const Color disabled = Color(0xFFE3E7F0);
  static const Color onDisabled = Color(0xFF8B93A5);

  // ---------------------------------------------------------------------
  // Material 3 role aliases
  //
  // Kept so existing screens keep compiling. New code should prefer the
  // brand ramps above, which say what the colour *means*.
  // ---------------------------------------------------------------------
  static const Color primary = sunStrong;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = sun;
  static const Color onPrimaryContainer = onSun;
  static const Color inversePrimary = sunDeep;
  static const Color surfaceTint = sunStrong;

  static const Color secondary = skyStrong;
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = sky;
  static const Color onSecondaryContainer = onSky;

  static const Color tertiary = streakStrong;
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = streakSoft;
  static const Color onTertiaryContainer = onStreak;

  static const Color primaryFixed = sun;
  static const Color primaryFixedDim = sunDeep;
  static const Color onPrimaryFixed = onSun;
  static const Color onPrimaryFixedVariant = sunStrong;

  static const Color secondaryFixed = skySoft;
  static const Color secondaryFixedDim = sky;
  static const Color onSecondaryFixed = onSky;
  static const Color onSecondaryFixedVariant = skyStrong;

  static const Color tertiaryFixed = streakSoft;
  static const Color tertiaryFixedDim = streak;
  static const Color onTertiaryFixed = onStreak;
  static const Color onTertiaryFixedVariant = streakStrong;

  /// Legacy soft-tone aliases kept for screens that already reference them.
  static const Color mintGreen = mint;
  static const Color onMintGreen = onMint;
  static const Color pastelPurple = violet;
  static const Color onPastelPurple = onViolet;

  /// Material 3 [ColorScheme] built from the tokens above.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
    inversePrimary: inversePrimary,
    surfaceTint: surfaceTint,
  );
}
