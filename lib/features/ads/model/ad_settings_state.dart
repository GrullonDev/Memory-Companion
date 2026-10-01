/// Lo que la base local recuerda de la publicidad.
class AdSettingsState {
  const AdSettingsState({
    required this.adsRemoved,
    required this.levelsCompletedCount,
  });

  static const AdSettingsState defaults = AdSettingsState(
    adsRemoved: false,
    levelsCompletedCount: 0,
  );

  /// El jugador compró "Sin anuncios".
  final bool adsRemoved;
  final int levelsCompletedCount;
}
