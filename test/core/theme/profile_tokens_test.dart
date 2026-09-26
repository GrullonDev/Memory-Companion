import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';

/// Guarda de los tokens por perfil.
///
/// El perfil accesible hace promesas concretas —más contraste, objetivos
/// táctiles mayores, sin movimiento— y estos tests son lo que impide que
/// un ajuste «estético» las rompa sin que nadie lo note.
void main() {
  double luminance(Color color) {
    double channel(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
  }

  const accessible = ProfileTokens.accessible;
  const vibrant = ProfileTokens.vibrant;

  group('perfil accesible', () {
    test('el texto secundario alcanza AAA (7:1)', () {
      expect(
        contrast(AppColors.surface, accessible.supportingTextColor),
        greaterThanOrEqualTo(7.0),
      );
    });

    test('los bordes con significado pasan 3:1 (WCAG 1.4.11)', () {
      expect(
        contrast(AppColors.surfaceContainerLowest, accessible.outlineColor),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('el dorso de la carta y su icono pasan AAA', () {
      expect(
        contrast(accessible.cardFaceDownColor, accessible.onCardFaceDownColor),
        greaterThanOrEqualTo(7.0),
      );
    });

    test('boca abajo y boca arriba se distinguen por luminosidad', () {
      // No basta con que difieran en tono: tiene que funcionar en gris.
      expect(
        contrast(
          accessible.cardFaceDownColor,
          AppColors.surfaceContainerLowest,
        ),
        greaterThanOrEqualTo(7.0),
      );
    });

    test('los objetivos táctiles superan el mínimo con holgura', () {
      expect(accessible.buttonMinHeight, greaterThan(vibrant.buttonMinHeight));
      expect(
        accessible.buttonMinHeight,
        greaterThanOrEqualTo(AppSize.touchComfortable),
      );
    });

    test('sin efectos decorativos ni movimiento', () {
      expect(accessible.celebrationEffects, isFalse);
      expect(accessible.reduceMotion, isTrue);
    });

    test('sube el suelo de la escala de texto sin pasar el techo auditado', () {
      expect(accessible.minTextScale, greaterThan(1.0));
      expect(accessible.maxTextScale, lessThanOrEqualTo(vibrant.maxTextScale));
    });
  });

  test('cada variante de botón pasa AA', () {
    for (final variant in AdaptiveButtonVariant.values) {
      expect(
        contrast(variant.background, variant.foreground),
        greaterThanOrEqualTo(4.5),
        reason: variant.name,
      );
    }
  });

  // Los widgets se prueban con un ThemeData mínimo que solo lleva los
  // tokens: `AppTheme` usa google_fonts, que en un test intenta descargar
  // las fuentes y falla sin red.
  ThemeData themeFor(VisualProfile profile) {
    return ThemeData(extensions: [ProfileTokens.forProfile(profile)]);
  }

  testWidgets('AdaptiveButton crece en el perfil accesible', (tester) async {
    Future<double> heightFor(VisualProfile profile) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themeFor(profile),
          home: Scaffold(
            body: AdaptiveButton(label: 'Jugar', onPressed: () {}),
          ),
        ),
      );
      // MaterialApp anima el cambio de tema; hay que dejar que termine.
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(AdaptiveButton)).height;
    }

    final vibrantHeight = await heightFor(VisualProfile.vibrant);
    final accessibleHeight = await heightFor(VisualProfile.accessible);

    expect(vibrantHeight, greaterThanOrEqualTo(vibrant.buttonMinHeight));
    expect(accessibleHeight, greaterThanOrEqualTo(accessible.buttonMinHeight));
    expect(accessibleHeight, greaterThan(vibrantHeight));
  });

  testWidgets('AdaptiveButton se anuncia como botón con su etiqueta', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveButton(
            label: 'Jugar otra vez',
            icon: Icons.refresh_rounded,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(AdaptiveButton)),
      matchesSemantics(
        label: 'Jugar otra vez',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });
}
