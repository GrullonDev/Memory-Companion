import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';

/// Lee y escribe las preferencias de presentación en la base local.
///
/// Sin red y sin cuenta: es una fila de SQLite. Mientras esa fila no exista
/// se sirven [DisplayPreferences.defaults], así que no hace falta sembrarla
/// en el primer arranque.
class DisplaySettingsRepository {
  DisplaySettingsRepository({
    required AppDatabase database,
    DateTime Function()? clock,
  }) : _db = database,
       _now = clock ?? DateTime.now;

  /// La tabla tiene exactamente una fila, siempre con esta clave.
  static const int singletonId = 0;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Emite las preferencias actuales y cada cambio posterior.
  Stream<DisplayPreferences> watch() {
    return _singleRow().watchSingleOrNull().map(
      (row) => row == null ? DisplayPreferences.defaults : _fromRow(row),
    );
  }

  Future<DisplayPreferences> read() async {
    final row = await _singleRow().getSingleOrNull();
    return row == null ? DisplayPreferences.defaults : _fromRow(row);
  }

  /// Cambia de perfil y devuelve el temporizador al valor por defecto de
  /// ese perfil: elegir el modo accesible apaga la cuenta atrás sin que el
  /// jugador tenga que encontrar un segundo interruptor.
  Future<void> setVisualProfile(VisualProfile profile) {
    return _upsert(
      DisplaySettingsCompanion(
        visualProfile: Value(profile),
        timedMatches: Value(profile.timedMatchesByDefault),
      ),
    );
  }

  Future<void> setTimedMatches(bool enabled) {
    return _upsert(DisplaySettingsCompanion(timedMatches: Value(enabled)));
  }

  Future<void> setContextLocation(bool enabled) {
    return _upsert(DisplaySettingsCompanion(contextLocation: Value(enabled)));
  }

  Future<void> setContextNearby(bool enabled) {
    return _upsert(DisplaySettingsCompanion(contextNearby: Value(enabled)));
  }

  Future<void> markMapNavigatorHintSeen() {
    return _upsert(
      const DisplaySettingsCompanion(mapNavigatorHintSeen: Value(true)),
    );
  }

  Future<void> _upsert(DisplaySettingsCompanion changes) {
    final updatedAt = Value(_now().millisecondsSinceEpoch);
    return _db
        .into(_db.displaySettings)
        .insert(
          changes.copyWith(id: const Value(singletonId), updatedAt: updatedAt),
          // Solo se reescriben las columnas presentes en [changes]: cambiar
          // el temporizador no debe devolver el perfil a su valor por defecto.
          onConflict: DoUpdate((_) => changes.copyWith(updatedAt: updatedAt)),
        );
  }

  SimpleSelectStatement<$DisplaySettingsTable, DisplaySettingsRow>
  _singleRow() {
    return _db.select(_db.displaySettings)
      ..where((s) => s.id.equals(singletonId));
  }

  static DisplayPreferences _fromRow(DisplaySettingsRow row) {
    return DisplayPreferences(
      visualProfile: row.visualProfile,
      timedMatches: row.timedMatches,
      contextLocation: row.contextLocation,
      contextNearby: row.contextNearby,
      mapNavigatorHintSeen: row.mapNavigatorHintSeen,
    );
  }
}
