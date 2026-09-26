import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_operation.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';

/// Sube a la cola todo el progreso que un jugador acumuló sin cuenta.
///
/// Se ejecuta una sola vez, al vincular. **No borra nada local**: la base
/// sigue siendo la fuente de verdad del gameplay, y lo que se encola son
/// órdenes de subida que el motor irá aplicando. Si la app muere a mitad, al
/// volver quedan las operaciones que faltaban y sigue donde estaba — no hay
/// rollback que escribir porque no hay nada que deshacer.
///
/// Los totales viajan como **deltas equivalentes al acumulado**. Es correcto
/// precisamente porque la adopción solo ocurre cuando el documento en la nube
/// no existe: sumar sobre cero da el total. Y mantiene una única regla en
/// todo el sistema —solo se sincronizan incrementos—, en vez de abrir una
/// excepción que luego alguien copiaría en el sitio equivocado.
class AccountMigration {
  AccountMigration({
    required AppDatabase database,
    required SyncQueue syncQueue,
    DateTime Function()? clock,
  })  : _db = database,
        _syncQueue = syncQueue,
        _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final SyncQueue _syncQueue;
  final DateTime Function() _now;

  /// Identificador **determinista** de una operación de migración.
  ///
  /// No es un UUID aleatorio a propósito. Con ids aleatorios, ejecutar la
  /// migración dos veces —algo que puede pasar si el proveedor se reconstruye
  /// durante la ventana en la que `cloudUid` aún no ha llegado a la UI—
  /// generaría un segundo juego de operaciones con ids distintos, y el
  /// servidor aplicaría **dos veces** el XP y las monedas acumuladas.
  ///
  /// Derivándolo del jugador y de la entidad, reencolar es un no-op real: la
  /// cola ignora el duplicado y el ledger remoto ya tenía ese id.
  static String _opId(String playerLocalId, String suffix) {
    return 'migration:$playerLocalId:$suffix';
  }

  /// Encola el estado completo del jugador. Devuelve cuántas operaciones creó.
  Future<int> enqueueFullState(String playerLocalId) {
    return _db.transaction(() async {
      final profile = await (_db.select(_db.playerProfiles)
            ..where((p) => p.localId.equals(playerLocalId)))
          .getSingleOrNull();
      if (profile == null) return 0;

      var enqueued = 0;
      Future<void> add(
        SyncOperationType type,
        String entityType,
        String entityId,
        Map<String, Object?> payload,
      ) async {
        await _syncQueue.enqueue(
          SyncOperationInput(
            opId: _opId(playerLocalId, '$entityType:$entityId:${type.name}'),
            playerLocalId: playerLocalId,
            type: type,
            entityType: entityType,
            entityId: entityId,
            payload: payload,
          ),
          now: _now(),
        );
        enqueued++;
      }

      // 1. Identidad y racha.
      await add(SyncOperationType.upsertProfile, 'player', playerLocalId, {
        'displayName': profile.displayName,
        'avatarSeed': profile.avatarSeed,
        'version': profile.version + 1,
      });
      await add(SyncOperationType.updateStreak, 'player', playerLocalId, {
        'currentStreak': profile.currentStreak,
        'longestStreak': profile.longestStreak,
        'lastPlayedDate': profile.lastPlayedDate,
      });

      // 2. Acumulados, como deltas sobre un documento que aún no existe.
      if (profile.totalXp > 0) {
        await add(SyncOperationType.addXp, 'player', playerLocalId, {
          'totalXp': profile.totalXp,
        });
      }
      if (profile.totalCoins > 0) {
        await add(SyncOperationType.earnCoins, 'player', playerLocalId, {
          'totalCoins': profile.totalCoins,
        });
      }

      // 3. Historial. Cada partida conserva el id que ya tenía, así que
      //    subirla dos veces sobrescribe el mismo documento.
      final matches = await (_db.select(_db.matches)
            ..where((m) => m.playerLocalId.equals(playerLocalId))
            ..orderBy([(m) => OrderingTerm.asc(m.playedAt)]))
          .get();
      for (final match in matches) {
        await add(SyncOperationType.createMatch, 'match', match.id, {
          'match': {
            'id': match.id,
            'gameMode': match.gameMode,
            'score': match.score,
            'moves': match.moves,
            'secondsElapsed': match.secondsElapsed,
            'timeLimit': match.timeLimit,
            'coinsEarned': match.coinsEarned,
            'xpEarned': match.xpEarned,
            'won': match.won,
            'playedAt': match.playedAt,
            'levelNumber': match.levelNumber,
          },
        });
      }

      // 4. Progreso de niveles.
      final levels = await (_db.select(_db.levelProgress)
            ..where((l) => l.playerLocalId.equals(playerLocalId))
            ..where((l) => l.isCompleted.equals(true)))
          .get();
      for (final level in levels) {
        await add(
          SyncOperationType.completeLevel,
          'level',
          '${level.levelNumber}',
          {
            'levelNumber': level.levelNumber,
            'bestScore': level.bestScore,
          },
        );
      }

      return enqueued;
    });
  }

  /// Sustituye el progreso local por el de la nube.
  ///
  /// Solo se llama cuando el jugador **elige explícitamente** quedarse con el
  /// progreso de su cuenta. Descarta la cola pendiente, porque esas
  /// operaciones describen un progreso que el jugador acaba de decidir no
  /// conservar; subirlas lo mezclaría con lo que pidió mantener.
  Future<void> adoptCloudProfile({
    required String playerLocalId,
    required Map<String, Object?> cloudProfile,
  }) {
    return _db.transaction(() async {
      int intOf(String key) {
        final value = cloudProfile[key];
        return value is int ? value : 0;
      }

      await (_db.update(_db.playerProfiles)
            ..where((p) => p.localId.equals(playerLocalId)))
          .write(
        PlayerProfilesCompanion(
          displayName: Value(
            cloudProfile['displayName'] is String
                ? cloudProfile['displayName']! as String
                : '',
          ),
          avatarSeed: Value(intOf('avatarSeed')),
          totalXp: Value(intOf('totalXp')),
          totalCoins: Value(intOf('totalCoins')),
          gamesWon: Value(intOf('gamesWon')),
          totalMoves: Value(intOf('totalMoves')),
          currentStreak: Value(intOf('currentStreak')),
          longestStreak: Value(intOf('longestStreak')),
          lastPlayedDate: Value(
            cloudProfile['lastPlayedDate'] is String
                ? cloudProfile['lastPlayedDate']! as String
                : null,
          ),
          updatedAt: Value(_now().millisecondsSinceEpoch),
        ),
      );

      await (_db.delete(_db.syncOperations)
            ..where((o) => o.playerLocalId.equals(playerLocalId))
            ..where((o) => o.status.equalsValue(SyncStatus.synced).not()))
          .go();
    });
  }
}
