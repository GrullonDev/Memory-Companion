import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/database/tables/player_profiles.dart';

/// Caché de la **definición** del reto diario, descargada de
/// `daily_challenges/{id}`.
///
/// Separar definición de progreso es lo que permite que el reto se pueda
/// jugar sin conexión: si el contenido de hoy ya se descargó, el jugador
/// puede completarlo aunque esté en el metro.
@DataClassName('DailyChallengeDefRow')
class DailyChallengeDefs extends Table {
  TextColumn get challengeId => text()();

  /// `'YYYY-MM-DD'` en zona local, para poder buscar el reto de hoy sin red.
  TextColumn get challengeDate => text()();

  /// Contenido del reto tal cual llegó, sin interpretar. Guardarlo opaco
  /// permite añadir tipos de reto sin migrar el esquema local.
  TextColumn get payloadJson => text()();

  IntColumn get cachedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {challengeId};
}

/// El **progreso** del jugador en un reto concreto. Local primero, nube
/// después.
@DataClassName('DailyChallengeProgressRow')
class DailyChallengeProgress extends Table {
  TextColumn get playerLocalId =>
      text().references(PlayerProfiles, #localId)();
  TextColumn get challengeId => text()();

  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  IntColumn get score => integer().withDefault(const Constant(0))();
  IntColumn get completedAt => integer().nullable()();

  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column<Object>> get primaryKey => {playerLocalId, challengeId};
}
