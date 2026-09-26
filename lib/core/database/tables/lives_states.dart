import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/tables/player_profiles.dart';

/// Economía de vidas, persistida.
///
/// Antes vivía solo en memoria con un `Timer`, así que cerrar y reabrir la
/// app devolvía las cinco vidas y el temporizador de recarga mentía. Con
/// [lastRefillAt] en disco, las vidas recuperadas se calculan desde el reloj
/// al arrancar en vez de depender de que la app siga viva.
@DataClassName('LivesStateRow')
class LivesStates extends Table {
  TextColumn get playerLocalId =>
      text().references(PlayerProfiles, #localId)();

  IntColumn get currentLives => integer()();

  /// Instante de la última recarga, en milisegundos de reloj local.
  IntColumn get lastRefillAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {playerLocalId};
}
