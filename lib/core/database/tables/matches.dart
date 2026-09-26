import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/database/tables/player_profiles.dart';

/// Una partida terminada. Inmutable una vez escrita.
///
/// [id] es el UUID que se genera **al iniciar** la partida, no al guardarla.
/// Ese detalle es lo que hace idempotente el guardado: reintentar la subida
/// sobrescribe el mismo documento en Firestore en lugar de crear otro.
@DataClassName('MatchRow')
@TableIndex(
  name: 'idx_matches_player_played_at',
  columns: {#playerLocalId, #playedAt},
)
@TableIndex(name: 'idx_matches_sync_status', columns: {#syncStatus})
class Matches extends Table {
  TextColumn get id => text()();
  TextColumn get playerLocalId =>
      text().references(PlayerProfiles, #localId)();

  /// `solo`, `versus`, `daily_challenge`.
  TextColumn get gameMode => text()();

  IntColumn get score => integer()();
  IntColumn get moves => integer()();
  IntColumn get secondsElapsed => integer()();
  IntColumn get timeLimit => integer()();
  IntColumn get coinsEarned => integer()();
  IntColumn get xpEarned => integer()();
  BoolColumn get won => boolean()();

  /// Reloj local en milisegundos. La hora del servidor se registra aparte al
  /// sincronizar, para poder contrastarlas.
  IntColumn get playedAt => integer()();

  /// Nivel jugado, cuando la partida viene del mapa de niveles.
  IntColumn get levelNumber => integer().nullable()();

  TextColumn get syncStatus => textEnum<SyncStatus>()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
