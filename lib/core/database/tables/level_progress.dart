import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/database/tables/player_profiles.dart';

/// Progreso del jugador en un nivel.
///
/// Aquí vive **solo el progreso**. La definición del nivel (tiempo límite,
/// número de cartas) es determinista y se genera en código con
/// `generateGameLevels`, así que no se guarda ni se sincroniza: eso es lo que
/// elimina las 50 escrituras por usuario nuevo del diseño anterior.
///
/// [bestScore] es un entero y se resuelve con `max`, no con last-write-wins:
/// si dos dispositivos jugaron el mismo nivel offline, gana la mejor marca.
@DataClassName('LevelProgressRow')
class LevelProgress extends Table {
  TextColumn get playerLocalId =>
      text().references(PlayerProfiles, #localId)();
  IntColumn get levelNumber => integer()();

  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get bestScore => integer().withDefault(const Constant(0))();
  IntColumn get completedAt => integer().nullable()();

  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column<Object>> get primaryKey => {playerLocalId, levelNumber};
}
