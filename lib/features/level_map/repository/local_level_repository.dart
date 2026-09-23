import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/features/level_map/model/level.dart';

/// Número de niveles del juego. Coincide con `generateGameLevels`.
const int kTotalLevels = 50;

/// Dueño del progreso de niveles en la base local.
///
/// El diseño anterior escribía **50 documentos en Firestore por cada usuario
/// nuevo**, con un contenido 100 % determinista. Aquí solo se guarda lo que
/// de verdad es del jugador —si completó el nivel y con qué marca—; la
/// definición (tiempo límite, número de cartas) se genera en código con
/// `generateGameLevels`.
///
/// El desbloqueo tampoco se almacena: un nivel está abierto si es el primero
/// o si el anterior está completado. Un dato que se puede deducir no debería
/// poder desincronizarse.
class LocalLevelRepository {
  LocalLevelRepository({
    required AppDatabase database,
    DateTime Function()? clock,
  })  : _db = database,
        _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// Los 50 niveles con el progreso del jugador ya aplicado.
  Stream<List<GameLevel>> watchLevels(String playerLocalId) {
    return (_db.select(_db.levelProgress)
          ..where((l) => l.playerLocalId.equals(playerLocalId)))
        .watch()
        .map(_composeLevels);
  }

  /// El nivel que le toca jugar: el primero sin completar.
  Future<int> currentLevelNumber(String playerLocalId) async {
    final rows = await (_db.select(_db.levelProgress)
          ..where((l) => l.playerLocalId.equals(playerLocalId)))
        .get();
    return _nextLevelAfter(rows);
  }

  /// Marca un nivel como completado y guarda la mejor marca.
  ///
  /// [bestScore] se resuelve con **máximo**, no con «gana el último»: si dos
  /// dispositivos jugaron el mismo nivel sin conexión, la marca buena es la
  /// mejor de las dos, no la que llegue más tarde.
  Future<void> completeLevel({
    required String playerLocalId,
    required int levelNumber,
    required int score,
  }) {
    return _db.transaction(() async {
      if (levelNumber < 1 || levelNumber > kTotalLevels) return;

      final existing = await (_db.select(_db.levelProgress)
            ..where((l) => l.playerLocalId.equals(playerLocalId))
            ..where((l) => l.levelNumber.equals(levelNumber)))
          .getSingleOrNull();

      final best = existing == null || score > existing.bestScore
          ? score
          : existing.bestScore;

      await _db.into(_db.levelProgress).insert(
            LevelProgressCompanion.insert(
              playerLocalId: playerLocalId,
              levelNumber: levelNumber,
              syncStatus: SyncStatus.pending,
              isCompleted: const Value(true),
              bestScore: Value(best),
              // La primera vez que se completó no se reescribe al repetirlo.
              completedAt: Value(
                existing?.completedAt ?? _now().millisecondsSinceEpoch,
              ),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }

  List<GameLevel> _composeLevels(List<LevelProgressRow> rows) {
    final completed = <int, bool>{};
    final bestScores = <int, int>{};

    for (final row in rows) {
      if (row.isCompleted) completed[row.levelNumber] = true;
      bestScores[row.levelNumber] = row.bestScore;
    }

    return generateGameLevels(
      unlockedUpToLevel: _nextLevelAfter(rows),
      bestScores: bestScores,
      completedLevels: completed,
    );
  }

  /// El primer nivel sin completar, contando desde el 1.
  ///
  /// No es «el más alto completado + 1»: si el jugador completó el 1 y el 3
  /// pero no el 2, le toca el 2. Contar hacia arriba evita dejar huecos
  /// abiertos por accidente.
  int _nextLevelAfter(List<LevelProgressRow> rows) {
    final completed = {
      for (final row in rows)
        if (row.isCompleted) row.levelNumber,
    };

    var level = 1;
    while (level < kTotalLevels && completed.contains(level)) {
      level++;
    }
    return level;
  }
}
