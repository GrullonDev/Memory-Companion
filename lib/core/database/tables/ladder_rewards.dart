import 'package:drift/drift.dart';

/// Hasta qué nivel de cada escalera se entregó ya el premio.
///
/// Cada juego sube su propia escalera de niveles y cada cierto número de
/// niveles completados gana un premio (`LevelRewards`). El nivel se deduce
/// de otras tablas —`category_levels` para el tablero de memoria,
/// `game_stats` para los minijuegos—; aquí solo se guarda lo que no se
/// puede deducir: qué premios ya se pagaron. Por eso reclamar dos veces no
/// paga dos veces.
///
/// **Solo local**: el premio en monedas viaja a la nube como cualquier otro
/// ingreso, por la cola de sincronización del perfil.
@DataClassName('LadderRewardRow')
class LadderRewards extends Table {
  /// Id de la escalera: `GameCategory.id` o `game:<BaseMinigame.id>`.
  TextColumn get ladderId => text()();

  /// Último nivel completado cuyo premio ya se entregó.
  ///
  /// Empieza en 0, así que quien ya iba por el Nivel 7 al actualizar recibe
  /// el premio del Nivel 5 que se había ganado.
  IntColumn get rewardedLevel => integer().withDefault(const Constant(0))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {ladderId};
}
