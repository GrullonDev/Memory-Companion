import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Carga y muestra intersticiales. Un anuncio nunca puede frenar el juego:
/// si no hay uno listo, o falla, [show] devuelve `false` al momento y la
/// partida sigue.
abstract interface class InterstitialAdService {
  /// Pide el siguiente anuncio en segundo plano. Si ya hay uno cargado o
  /// cargándose no hace nada.
  void preload();

  /// Muestra el anuncio cargado y termina cuando el jugador lo cierra.
  /// `false` si no había ninguno listo o no se pudo mostrar.
  Future<bool> show();

  /// Suelta el anuncio cargado, si lo hay.
  void dispose();
}

/// Para plataformas sin AdMob y para quien compró "Sin anuncios".
class NoInterstitialAdService implements InterstitialAdService {
  const NoInterstitialAdService();

  @override
  void preload() {}

  @override
  Future<bool> show() async => false;

  @override
  void dispose() {}
}

class AdMobInterstitialService implements InterstitialAdService {
  AdMobInterstitialService({required this.adUnitId});

  final String adUnitId;

  Future<InitializationStatus>? _initialization;
  InterstitialAd? _ad;
  bool _loading = false;

  @override
  void preload() {
    if (_ad != null || _loading) return;
    _loading = true;
    _initialization ??= MobileAds.instance.initialize();
    unawaited(
      _initialization!
          .then(
            (_) => InterstitialAd.load(
              adUnitId: adUnitId,
              request: const AdRequest(),
              adLoadCallback: InterstitialAdLoadCallback(
                onAdLoaded: (ad) {
                  _ad = ad;
                  _loading = false;
                },
                onAdFailedToLoad: (error) {
                  _loading = false;
                  debugPrint('Interstitial failed to load: $error');
                },
              ),
            ),
          )
          .catchError((Object error) {
            _loading = false;
            debugPrint('AdMob failed to start: $error');
          }),
    );
  }

  @override
  Future<bool> show() async {
    final ad = _ad;
    if (ad == null) return false;
    // Un intersticial se muestra una sola vez.
    _ad = null;

    final closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        if (!closed.isCompleted) closed.complete(false);
      },
    );
    try {
      await ad.show();
    } catch (error) {
      debugPrint('Interstitial failed to show: $error');
      unawaited(ad.dispose());
      return false;
    }
    return closed.future;
  }

  @override
  void dispose() {
    unawaited(_ad?.dispose());
    _ad = null;
  }
}
