import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_motion.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/app_typography.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';

/// Assembles every design token into the single [ThemeData] the app runs on.
///
/// Before this existed the app built its theme from
/// `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`, so every Material
/// default — snack bars, progress spinners, text buttons, dialogs, text
/// styles — ignored the design system entirely. Wiring the real scheme here
/// is what makes the tokens actually reach the screen.
///
/// The [VisualProfile] only changes what Material draws by default — button
/// sizes, supporting-text contrast, divider strength — and attaches the
/// matching [ProfileTokens]. Colour tokens and type sizes stay the same
/// objects in both profiles; text grows through the app-wide text scale.
abstract final class AppTheme {
  static ThemeData light({VisualProfile profile = VisualProfile.vibrant}) {
    final tokens = ProfileTokens.forProfile(profile);
    final scheme = profile.isAccessible
        ? _accessibleScheme
        : AppColors.lightScheme;
    final textTheme = AppTypography.textTheme;
    final touchTarget = profile.isAccessible
        ? tokens.buttonMinHeight
        : AppSize.touchMin;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: [tokens],
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,

      // Android gets the zoom transition so navigation feels like part of
      // the same system as the card presses. iOS keeps its native
      // edge-swipe-back transition, which players there expect.
      // The accessible profile drops the zoom for a plain fade: no surface
      // flies at the player between screens.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: profile.isAccessible
              ? const FadeForwardsPageTransitionsBuilder()
              : const ZoomPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sun,
          foregroundColor: AppColors.onSun,
          disabledBackgroundColor: AppColors.disabled,
          disabledForegroundColor: AppColors.onDisabled,
          minimumSize: Size.fromHeight(
            profile.isAccessible
                ? tokens.buttonMinHeight
                : AppSize.touchComfortable,
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.skyStrong,
          minimumSize: Size(touchTarget, touchTarget),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          minimumSize: Size.fromHeight(
            profile.isAccessible
                ? tokens.buttonMinHeight
                : AppSize.touchComfortable,
          ),
          side: BorderSide(color: tokens.outlineColor, width: 2),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(touchTarget, touchTarget),
          foregroundColor: tokens.supportingTextColor,
        ),
      ),

      iconTheme: IconThemeData(
        color: tokens.supportingTextColor,
        size: profile.isAccessible ? AppSize.iconLg : AppSize.iconMd,
      ),

      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: const StadiumBorder(),
      ),

      dividerTheme: DividerThemeData(
        color: tokens.outlineColor,
        thickness: 1,
        space: AppSpacing.xxl,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.sunDeep,
        linearTrackColor: AppColors.surfaceContainerHigh,
        circularTrackColor: AppColors.surfaceContainerHigh,
        linearMinHeight: AppSize.progressBarHeight,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.inverseOnSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: AppColors.sun,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: tokens.supportingTextColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xxl),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.outline),
        labelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.outlineVariant,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.sky, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 2.5),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        waitDuration: AppMotion.slow,
        decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.inverseOnSurface,
        ),
      ),
    );
  }

  /// [AppColors.lightScheme] with every "quiet" role promoted one step:
  /// supporting text becomes full-strength ink (15.9:1) and outlines become
  /// the 7.6:1 slate, so no information depends on a pale grey.
  static final ColorScheme _accessibleScheme = AppColors.lightScheme.copyWith(
    onSurfaceVariant: AppColors.onSurface,
    outline: AppColors.onSurfaceVariant,
    outlineVariant: AppColors.outline,
  );
}
