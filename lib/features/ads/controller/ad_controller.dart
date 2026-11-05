import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/ads/model/ad_settings_state.dart';
import 'package:memory_companion/features/ads/model/ads_config.dart';
import 'package:memory_companion/features/ads/repository/ads_repository.dart';
import 'package:memory_companion/features/ads/service/interstitial_ad_service.dart';

/// Si este dispositivo tiene AdMob y tienda. Se sobrescribe en los tests.
final adsPlatformSupportedProvider = Provider<bool>(
  (ref) => AdsConfig.storeSupported,
);

final adsRepositoryProvider = Provider<AdsRepository>(
  (ref) => AdsRepository(database: ref.watch(appDatabaseProvider)),
);

final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  final InterstitialAdService service = ref.watch(adsPlatformSupportedProvider)
      ? AdMobInterstitialService(adUnitId: AdsConfig.interstitialUnitId)
      : const NoInterstitialAdService();
  ref.onDispose(service.dispose);
  return service;
});

/// Lo que la base local recuerda de la publicidad, con cada cambio.
final adSettingsProvider = StreamProvider<AdSettingsState>(
  (ref) => ref.watch(adsRepositoryProvider).watch(),
);

/// Si el jugador compró "Sin anuncios". `false` mientras la base carga: la
/// decisión de mostrar un anuncio no se toma con esto, sino con
/// [AdController], que lee la base antes de cada intersticial.
final hasRemovedAdsProvider = Provider<bool>(
  (ref) => ref.watch(adSettingsProvider).value?.adsRemoved ?? false,
);

/// Decide cuándo toca un intersticial: cada
/// [AdsConfig.interstitialEveryLevels] niveles completados, y nunca para
/// quien compró "Sin anuncios".
///
/// Las pantallas llaman a [onLevelCompleted] cuando el jugador sigue tras
/// ganar un nivel, antes de empezar el siguiente. Perder o reintentar no
/// pasa por aquí, así que nunca sale un anuncio tras un error.
class AdController extends Notifier<void> {
  @override
  void build() {
    // El anuncio precargado tiene que sobrevivir entre pantallas.
    ref.keepAlive();
    if (!ref.watch(adsPlatformSupportedProvider)) return;
    ref.listen(adSettingsProvider, (_, next) {
      final settings = next.value;
      if (settings == null) return;
      final service = ref.read(interstitialAdServiceProvider);
      if (settings.adsRemoved) {
        service.dispose();
      } else {
        service.preload();
      }
    }, fireImmediately: true);
  }

  bool _busy = false;

  /// Cuenta el nivel completado y, si toca, muestra el intersticial. Termina
  /// cuando el jugador cierra el anuncio, o enseguida si no hay que mostrar
  /// ninguno o no hay uno listo. Nunca lanza.
  ///
  /// Devuelve `false` si ya había una llamada en curso (un doble toque en
  /// "Siguiente nivel"): quien llama no debe avanzar dos veces.
  Future<bool> onLevelCompleted() async {
    // Sin AdMob no hay nada que contar: ni siquiera se toca la base.
    if (!ref.read(adsPlatformSupportedProvider)) return true;
    if (_busy) return false;
    _busy = true;
    try {
      final repository = ref.read(adsRepositoryProvider);
      if ((await repository.read()).adsRemoved) return true;
      final completed = await repository.recordLevelCompleted();
      if (!ref.mounted || !AdsConfig.isInterstitialDue(completed)) return true;

      final service = ref.read(interstitialAdServiceProvider);
      await service.show();
      if (ref.mounted) service.preload();
    } catch (error, stack) {
      debugPrint('Ad flow failed, continuing without ad: $error\n$stack');
    } finally {
      _busy = false;
    }
    return true;
  }
}

final adControllerProvider = NotifierProvider<AdController, void>(
  AdController.new,
);
