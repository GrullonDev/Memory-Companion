import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Qué se monetiza y cada cuánto.
///
/// Los IDs de AdMob salen de `--dart-define`. Sin ellos se usan los de
/// prueba de Google, que solo sirven anuncios de prueba y no generan
/// ingresos, así que un build sin configurar nunca pide anuncios reales:
///
/// ```bash
/// flutter build appbundle \
///   --dart-define=ADMOB_INTERSTITIAL_ANDROID=ca-app-pub-xxx/yyy \
///   --dart-define=ADMOB_INTERSTITIAL_IOS=ca-app-pub-xxx/zzz
/// ```
abstract final class AdsConfig {
  /// Un intersticial cada tantos niveles completados.
  static const int interstitialEveryLevels = 3;

  /// Producto no consumible de Google Play y App Store Connect.
  static const String removeAdsProductId = 'remove_ads';

  static const String _androidInterstitialId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_ANDROID',
    defaultValue: 'ca-app-pub-3940256099942544/1033173712',
  );

  static const String _iosInterstitialId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_IOS',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );

  /// AdMob y las compras integradas solo existen en Android e iOS. En el
  /// resto (escritorio, web, tests) la app se comporta como sin anuncios y
  /// sin tienda.
  static bool get storeSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static String get interstitialUnitId =>
      Platform.isIOS ? _iosInterstitialId : _androidInterstitialId;

  /// Si al completar el nivel número [levelsCompleted] toca un intersticial.
  static bool isInterstitialDue(int levelsCompleted) =>
      levelsCompleted > 0 && levelsCompleted % interstitialEveryLevels == 0;
}
