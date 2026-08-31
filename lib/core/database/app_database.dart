import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/connection/open_connection.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/database/tables/daily_challenges.dart';
import 'package:memory_companion/core/database/tables/level_progress.dart';
import 'package:memory_companion/core/database/tables/lives_states.dart';
import 'package:memory_companion/core/database/tables/matches.dart';
import 'package:memory_companion/core/database/tables/player_profiles.dart';
import 'package:memory_companion/core/database/tables/sync_operations.dart';

part 'app_database.g.dart';

/// La base local: fuente de verdad del gameplay.
///
/// Todo lo que el jugador hace se escribe aquí primero y se sirve desde aquí.
/// Firestore sincroniza esta base; no la sustituye. Ninguna pantalla observa
/// Firestore directamente.
///
/// Para regenerar el código tras tocar una tabla:
/// `dart run build_runner build --delete-conflicting-outputs`
@DriftDatabase(
  tables: [
    PlayerProfiles,
    Matches,
    LevelProgress,
    DailyChallengeDefs,
    DailyChallengeProgress,
    LivesStates,
    SyncOperations,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Base real, sobre el sistema de archivos del dispositivo.
  AppDatabase() : super(openConnection());

  /// Base arbitraria — se usa con `NativeDatabase.memory()` en los tests,
  /// que es lo que permite probar toda la capa local sin Firebase ni disco.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      beforeOpen: (OpeningDetails details) async {
        // SQLite ignora las claves foráneas salvo que se pidan explícitamente,
        // y las queremos: una partida huérfana o una operación en cola sin
        // jugador son estados que preferimos que fallen al escribirse antes
        // que descubrirlos al sincronizar.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}
