import 'package:drift/drift.dart';

/// El jugador, con o sin cuenta.
///
/// [localId] es un UUID generado en el primer arranque y **nunca cambia**.
/// Crear una cuenta no crea una fila nueva: rellena [cloudUid] sobre esta
/// misma. Eso es lo que hace que vincular no pueda perder progreso — no hay
/// traspaso, hay vinculación.
///
/// Los acumulados ([totalXp], [totalCoins], [gamesWon], [totalMoves]) son
/// monótonos y se sincronizan como incrementos, nunca como totales. El nivel
/// y el progreso de la barra **no se guardan**: se derivan de [totalXp].
@DataClassName('PlayerProfileRow')
class PlayerProfiles extends Table {
  TextColumn get localId => text()();

  /// UID de Firebase, o null mientras el jugador no tenga cuenta.
  TextColumn get cloudUid => text().nullable()();

  TextColumn get displayName => text().withDefault(const Constant(''))();
  IntColumn get avatarSeed => integer().withDefault(const Constant(0))();

  /// XP acumulado de por vida. Monótono: nunca baja.
  IntColumn get totalXp => integer().withDefault(const Constant(0))();
  IntColumn get totalCoins => integer().withDefault(const Constant(0))();
  IntColumn get gamesWon => integer().withDefault(const Constant(0))();
  IntColumn get totalMoves => integer().withDefault(const Constant(0))();

  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();

  /// Último día jugado como `'YYYY-MM-DD'` en zona **local**.
  ///
  /// Texto y no timestamp: la racha tiene que resolverse sin servidor y
  /// sobrevivir a un cambio de huso horario sin saltar ni romperse.
  TextColumn get lastPlayedDate => text().nullable()();

  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  /// Contador para resolver conflictos last-write-wins en los campos de
  /// perfil (nombre, avatar), que no son acumulables.
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}
