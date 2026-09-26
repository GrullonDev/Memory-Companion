import 'package:drift/drift.dart';

/// Nivel explícito y estado de la dificultad adaptativa, uno por categoría.
///
/// Es la persistencia de `SkillState`: el nivel que ve el jugador y el
/// tablero que ese nivel reparte se guardan en la misma fila, así que no
/// pueden desincronizarse. Sin esta tabla la habilidad vivía solo en memoria
/// y, al reabrir la app, un "Nivel 12" habría repartido un tablero de
/// principiante.
///
/// **Solo local**, como `GameStats`: no referencia a `PlayerProfiles` ni
/// pasa por la cola de sincronización. La progresión tiene que funcionar sin
/// cuenta y sin red, y no depende de que el perfil ya esté resuelto.
@DataClassName('CategoryLevelRow')
class CategoryLevels extends Table {
  /// `GameCategory.id`.
  TextColumn get categoryId => text()();

  /// Empieza en 1 y sube uno por cada tablero ganado. Nunca baja.
  IntColumn get level => integer().withDefault(const Constant(1))();

  /// `SkillState.skill`, de 0 a 1.
  RealColumn get skill => real()();
  IntColumn get pairCount => integer()();
  IntColumn get consecutiveLosses =>
      integer().withDefault(const Constant(0))();
  IntColumn get roundsPlayed => integer().withDefault(const Constant(0))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {categoryId};
}
