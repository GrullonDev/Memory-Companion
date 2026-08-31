import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Type tokens.
///
/// Two families, each doing one job:
///  * **Quicksand** — headings, titles, scores. Rounded terminals match the
///    squircle geometry and read as friendly without reading as childish.
///  * **Plus Jakarta Sans** — body, labels, buttons. A tall x-height and open
///    apertures keep it legible at 13px and for readers with low vision.
///
/// Sizes start one step larger than Material's defaults on purpose: the
/// smallest text in the product is 13px, and every size below 15px is
/// reserved for metadata that is never the only way to get information.
abstract final class AppTypography {
  static TextStyle _display(double size, double height, {FontWeight w = FontWeight.w700, double? spacing}) {
    return GoogleFonts.quicksand(
      fontSize: size,
      height: height / size,
      fontWeight: w,
      letterSpacing: spacing,
    );
  }

  static TextStyle _body(double size, double height, {FontWeight w = FontWeight.w400, double? spacing}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      height: height / size,
      fontWeight: w,
      letterSpacing: spacing,
    );
  }

  /// The full scale, tinted for a light surface.
  static TextTheme get textTheme {
    return TextTheme(
      // Splash screens and big-win moments only.
      displayLarge: _display(40, 48, spacing: -0.5),
      displayMedium: _display(34, 42, spacing: -0.4),
      displaySmall: _display(30, 38, spacing: -0.3),

      // Screen titles.
      headlineLarge: _display(28, 36, spacing: -0.2),
      headlineMedium: _display(24, 32),
      headlineSmall: _display(21, 28),

      // Card titles and section headers.
      titleLarge: _display(20, 28),
      titleMedium: _display(17, 24),
      titleSmall: _body(15, 20, w: FontWeight.w700),

      // Reading copy.
      bodyLarge: _body(17, 26, w: FontWeight.w500),
      bodyMedium: _body(15, 22),
      bodySmall: _body(13, 18),

      // Buttons, chips, metadata.
      labelLarge: _body(15, 20, w: FontWeight.w700, spacing: 0.2),
      labelMedium: _body(13, 16, w: FontWeight.w700, spacing: 0.3),
      labelSmall: _body(12, 16, w: FontWeight.w700, spacing: 0.4),
    ).apply(
      bodyColor: AppColors.onSurface,
      displayColor: AppColors.onSurface,
    );
  }

  /// Numbers that change in place — scores, coins, XP, timers.
  ///
  /// Tabular figures stop the layout from twitching as digits update, which
  /// matters a lot on a scoreboard and during a countdown.
  static TextStyle score(
    BuildContext context, {
    double size = 24,
    Color? color,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.quicksand(
      fontSize: size,
      height: 1.15,
      fontWeight: weight,
      color: color ?? AppColors.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// An all-caps eyebrow above a heading. Wide tracking keeps it readable
  /// at small sizes, where caps normally hurt legibility.
  static TextStyle eyebrow(BuildContext context, {Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.0,
      color: color ?? AppColors.onSurfaceVariant,
    );
  }
}
