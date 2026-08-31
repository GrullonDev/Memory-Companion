import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/theme/app_colors.dart';

/// Guarda de contraste del Design System.
///
/// Sustituye al test de contador que venía por defecto con el proyecto, que
/// probaba un widget que nunca existió. Este sí defiende algo real: los pares
/// de color que la auditoría de UI documentó como conformes a WCAG AA.
///
/// El contraste es la propiedad más fácil de romper sin darse cuenta —basta
/// con que alguien aclare un amarillo «para que se vea mejor»— y la más cara
/// para el público del producto, que llega hasta los 50+. Que falle el test
/// antes que el usuario.
void main() {
  /// Luminancia relativa según WCAG 2.1.
  double relativeLuminance(Color color) {
    double channel(double value) {
      return value <= 0.03928
          ? value / 12.92
          : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }

  /// Ratio de contraste entre dos colores opacos, de 1:1 a 21:1.
  double contrastRatio(Color a, Color b) {
    final lumA = relativeLuminance(a);
    final lumB = relativeLuminance(b);
    final lighter = math.max(lumA, lumB);
    final darker = math.min(lumA, lumB);
    return (lighter + 0.05) / (darker + 0.05);
  }

  void expectAA(String label, Color background, Color foreground) {
    final ratio = contrastRatio(background, foreground);
    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: '$label alcanza ${ratio.toStringAsFixed(2)}:1, '
          'por debajo del mínimo AA de 4.5:1 para texto',
    );
  }

  group('rellenos de marca y su color de texto', () {
    test('cada familia pasa AA con su propio tinte oscuro', () {
      expectAA('sun / onSun', AppColors.sun, AppColors.onSun);
      expectAA('sky / onSky', AppColors.sky, AppColors.onSky);
      expectAA('mint / onMint', AppColors.mint, AppColors.onMint);
      expectAA('violet / onViolet', AppColors.violet, AppColors.onViolet);
      expectAA('streak / onStreak', AppColors.streak, AppColors.onStreak);
    });

    test('el blanco sobre un relleno de marca NO pasa AA', () {
      // Documenta por qué el sistema usa tintes oscuros del propio tono en
      // lugar de blanco: es el error más común en juegos con esta estética.
      for (final fill in [AppColors.sun, AppColors.mint, AppColors.sky]) {
        expect(contrastRatio(fill, Colors.white), lessThan(4.5));
      }
    });
  });

  group('tintes claros con su color fuerte', () {
    test('los pozos de icono sobre blanco pasan AA', () {
      expectAA('sunSoft / sunStrong', AppColors.sunSoft, AppColors.sunStrong);
      expectAA('skySoft / skyStrong', AppColors.skySoft, AppColors.skyStrong);
      expectAA(
        'mintSoft / mintStrong',
        AppColors.mintSoft,
        AppColors.mintStrong,
      );
      expectAA(
        'violetSoft / violetStrong',
        AppColors.violetSoft,
        AppColors.violetStrong,
      );
      expectAA(
        'streakSoft / streakStrong',
        AppColors.streakSoft,
        AppColors.streakStrong,
      );
    });
  });

  group('neutros', () {
    test('el texto principal supera holgadamente AAA', () {
      expect(
        contrastRatio(AppColors.surfaceContainerLowest, AppColors.onSurface),
        greaterThanOrEqualTo(7.0),
      );
    });

    test('el texto secundario y los metadatos pasan AA', () {
      expectAA('surface / onSurfaceVariant', AppColors.surface,
          AppColors.onSurfaceVariant);
      // `outline` se usa en textos de 12px, donde AA no da margen: por eso
      // reemplazó al tono oliva anterior, que se quedaba justo en 4.5:1.
      expectAA(
        'blanco / outline',
        AppColors.surfaceContainerLowest,
        AppColors.outline,
      );
    });
  });
}
