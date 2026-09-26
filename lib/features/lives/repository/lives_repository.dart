import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';

/// Persistencia de la economía de vidas.
class LivesRepository {
  LivesRepository({required AppDatabase database}) : _db = database;

  final AppDatabase _db;

  /// Lee el estado guardado, creándolo con [initialLives] la primera vez.
  Future<LivesStateRow> ensure({
    required String playerLocalId,
    required int initialLives,
    required DateTime now,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.livesStates)
            ..where((l) => l.playerLocalId.equals(playerLocalId)))
          .getSingleOrNull();
      if (existing != null) return existing;

      return _db.into(_db.livesStates).insertReturning(
            LivesStatesCompanion.insert(
              playerLocalId: playerLocalId,
              currentLives: initialLives,
              lastRefillAt: now.millisecondsSinceEpoch,
            ),
          );
    });
  }

  Future<void> save({
    required String playerLocalId,
    required int currentLives,
    required DateTime lastRefillAt,
  }) {
    return _db.into(_db.livesStates).insert(
          LivesStatesCompanion.insert(
            playerLocalId: playerLocalId,
            currentLives: currentLives,
            lastRefillAt: lastRefillAt.millisecondsSinceEpoch,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }
}
