import 'package:drift/drift.dart';

/// Estado de la publicidad del dispositivo. Una sola fila.
///
/// Igual que `DisplaySettings`, es del dispositivo y no pasa por la cola de
/// sincronización: la compra la guarda la tienda (Google Play / App Store),
/// y aquí solo se recuerda para no tener que preguntarle en cada arranque.
/// "Restaurar compras" vuelve a escribir esta fila desde la tienda.
@DataClassName('AdSettingsRow')
class AdSettings extends Table {
  /// Siempre `AdsRepository.singletonId`.
  IntColumn get id => integer()();

  /// El jugador compró `remove_ads`. Con esto en `true` no se carga ni se
  /// muestra ningún anuncio.
  BoolColumn get adsRemoved => boolean().withDefault(const Constant(false))();

  /// Niveles completados desde que se instaló la app. Cada
  /// `AdsConfig.interstitialEveryLevels` toca un intersticial.
  IntColumn get levelsCompletedCount =>
      integer().withDefault(const Constant(0))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
