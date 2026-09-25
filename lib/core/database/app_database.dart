import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/connection/open_connection.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/database/tables/category_levels.dart';
import 'package:memory_companion/core/database/tables/daily_challenges.dart';
import 'package:memory_companion/core/database/tables/display_settings.dart';
import 'package:memory_companion/core/database/tables/game_stats.dart';
import 'package:memory_companion/core/database/tables/ladder_rewards.dart';
import 'package:memory_companion/core/database/tables/level_progress.dart';
import 'package:memory_companion/core/database/tables/lives_states.dart';
import 'package:memory_companion/core/database/tables/matches.dart';
import 'package:memory_companion/core/database/tables/places.dart';
import 'package:memory_companion/core/database/tables/player_profiles.dart';
import 'package:memory_companion/core/database/tables/sync_operations.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';

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
    DisplaySettings,
    GameStats,
    CategoryLevels,
    Places,
    LadderRewards,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Base real, sobre el sistema de archivos del dispositivo.
  AppDatabase() : super(openConnection());

  /// Base arbitraria — se usa con `NativeDatabase.memory()` en los tests,
  /// que es lo que permite probar toda la capa local sin Firebase ni disco.
  AppDatabase.forTesting(super.executor);

  /// Historial:
  ///  1. Esquema inicial.
  ///  2. `display_settings` — perfil visual y temporizador.
  ///  3. `game_stats` — métricas locales para el panel de estadísticas.
  ///  4. `daily_challenge_progress` guarda movimientos, tiempo, pistas y la
  ///     cuadrícula del resultado, para poder volver a compartirlo.
  ///  5. `category_levels` — nivel explícito y habilidad adaptativa por
  ///     categoría, para que la progresión sobreviva al cierre de la app.
  ///  6. Contexto automático: `places`, el lugar y los jugadores cercanos de
  ///     cada partida en `game_stats`, y los dos permisos opcionales en
  ///     `display_settings`. Todo solo local.
  ///  7. `ladder_rewards` — premios ya entregados de la escalera de niveles
  ///     de cada juego.
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) await m.createTable(displaySettings);
        if (from < 3) {
          await m.createTable(gameStats);
          await m.createIndex(idxGameStatsPlayedAt);
          await m.createIndex(idxGameStatsPlayedDay);
        }
        if (from < 4) {
          final progress = dailyChallengeProgress;
          await m.addColumn(progress, progress.moves);
          await m.addColumn(progress, progress.elapsedSeconds);
          await m.addColumn(progress, progress.hintsUsed);
          await m.addColumn(progress, progress.grid);
        }
        if (from < 5) await m.createTable(categoryLevels);
        if (from < 6) {
          await m.createTable(places);
          await m.addColumn(gameStats, gameStats.placeId);
          await m.addColumn(gameStats, gameStats.nearby);
          final settings = displaySettings;
          await m.addColumn(settings, settings.contextLocation);
          await m.addColumn(settings, settings.contextNearby);
        }
        if (from < 7) await m.createTable(ladderRewards);
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
