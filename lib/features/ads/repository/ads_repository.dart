import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/ads/model/ad_settings_state.dart';

/// Lee y escribe el estado de la publicidad en la base local.
///
/// Mientras la fila no exista se sirven [AdSettingsState.defaults].
class AdsRepository {
  AdsRepository({required AppDatabase database, DateTime Function()? clock})
    : _db = database,
      _now = clock ?? DateTime.now;

  /// La tabla tiene exactamente una fila, siempre con esta clave.
  static const int singletonId = 0;

  final AppDatabase _db;
  final DateTime Function() _now;

  Stream<AdSettingsState> watch() {
    return _singleRow().watchSingleOrNull().map(_fromRow);
  }

  Future<AdSettingsState> read() async {
    return _fromRow(await _singleRow().getSingleOrNull());
  }

  Future<void> setAdsRemoved(bool removed) {
    final changes = AdSettingsCompanion(
      adsRemoved: Value(removed),
      updatedAt: Value(_now().millisecondsSinceEpoch),
    );
    return _db
        .into(_db.adSettings)
        .insert(
          changes.copyWith(id: const Value(singletonId)),
          onConflict: DoUpdate((_) => changes),
        );
  }

  /// Suma un nivel completado y devuelve el total nuevo.
  Future<int> recordLevelCompleted() {
    return _db.transaction(() async {
      final updatedAt = Value(_now().millisecondsSinceEpoch);
      await _db
          .into(_db.adSettings)
          .insert(
            AdSettingsCompanion(
              id: const Value(singletonId),
              levelsCompletedCount: const Value(1),
              updatedAt: updatedAt,
            ),
            onConflict: DoUpdate(
              (old) => AdSettingsCompanion.custom(
                levelsCompletedCount:
                    old.levelsCompletedCount + const Constant(1),
                updatedAt: Constant(updatedAt.value),
              ),
            ),
          );
      return (await read()).levelsCompletedCount;
    });
  }

  SimpleSelectStatement<$AdSettingsTable, AdSettingsRow> _singleRow() {
    return _db.select(_db.adSettings)..where((s) => s.id.equals(singletonId));
  }

  static AdSettingsState _fromRow(AdSettingsRow? row) {
    if (row == null) return AdSettingsState.defaults;
    return AdSettingsState(
      adsRemoved: row.adsRemoved,
      levelsCompletedCount: row.levelsCompletedCount,
    );
  }
}
