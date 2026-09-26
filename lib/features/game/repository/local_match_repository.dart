import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_operation.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/game/model/match_rewards.dart';
import 'package:memory_companion/features/level_map/repository/local_level_repository.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

/// Dueño de la tabla `matches` en la base local.
///
/// Su método central, [recordMatch], escribe la partida **y** aplica sus
/// recompensas dentro de una sola transacción. Separarlos permitiría estados
/// imposibles de justificar: una partida sin premio, o monedas sin partida
/// que las explique.
///
/// Es idempotente por [matchId]: registrar dos veces la misma partida no
/// duplica ni la fila ni las recompensas. Ese es el ensayo de lo que hará el
/// motor de sincronización cuando reintente una operación cuya respuesta se
/// perdió.
class LocalMatchRepository {
  LocalMatchRepository({
    required AppDatabase database,
    required PlayerRepository playerRepository,
    required LocalLevelRepository levelRepository,
    required SyncQueue syncQueue,
    String Function()? idGenerator,
    DateTime Function()? clock,
  })  : _db = database,
        _playerRepository = playerRepository,
        _levelRepository = levelRepository,
        _syncQueue = syncQueue,
        _newId = idGenerator ?? _defaultIdGenerator,
        _now = clock ?? DateTime.now;

  static String _defaultIdGenerator() => const Uuid().v4();

  final AppDatabase _db;
  final PlayerRepository _playerRepository;
  final LocalLevelRepository _levelRepository;
  final SyncQueue _syncQueue;
  final String Function() _newId;
  final DateTime Function() _now;

  /// Registra una partida terminada y entrega sus recompensas.
  ///
  /// Devuelve `true` si la partida era nueva, `false` si ya estaba registrada
  /// —en cuyo caso no se toca nada.
  Future<bool> recordMatch({
    required String matchId,
    required String playerLocalId,
    required String gameMode,
    required int score,
    required int moves,
    required int secondsElapsed,
    required int timeLimit,
    required MatchRewards rewards,
    required bool won,
    int? levelNumber,
    DateTime? playedAt,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.matches)
            ..where((m) => m.id.equals(matchId)))
          .getSingleOrNull();
      if (existing != null) return false;

      await _db.into(_db.matches).insert(
            MatchesCompanion.insert(
              id: matchId,
              playerLocalId: playerLocalId,
              gameMode: gameMode,
              score: score,
              moves: moves,
              secondsElapsed: secondsElapsed,
              timeLimit: timeLimit,
              coinsEarned: rewards.coins,
              xpEarned: rewards.xp,
              won: won,
              playedAt: (playedAt ?? _now()).millisecondsSinceEpoch,
              levelNumber: Value(levelNumber),
              // Nace pendiente: si el jugador tiene cuenta, el motor de
              // sincronización la subirá; si no, espera a que la cree.
              syncStatus: SyncStatus.pending,
            ),
          );

      await _playerRepository.applyMatchOutcome(
        localId: playerLocalId,
        coinsEarned: rewards.coins,
        xpEarned: rewards.xp,
        movesUsed: moves,
        won: won,
      );

      // Ganar un nivel lo marca y abre el siguiente, en esta misma
      // transacción: no puede quedar una victoria que no desbloqueó nada.
      if (won && levelNumber != null) {
        await _levelRepository.completeLevel(
          playerLocalId: playerLocalId,
          levelNumber: levelNumber,
          score: score,
        );
      }

      // Una sola operación por partida: la fila, los deltas, la racha y el
      // nivel viajan juntos y se aplican en una única transacción remota.
      // Trocearlo permitiría que la nube quedara en un estado intermedio que
      // nunca existió en el dispositivo.
      final updated = await _playerRepository.readLocalProfile();
      await _syncQueue.enqueue(
        SyncOperationInput(
          opId: _newId(),
          playerLocalId: playerLocalId,
          type: SyncOperationType.recordMatch,
          entityType: 'match',
          entityId: matchId,
          payload: {
            'match': {
              'id': matchId,
              'gameMode': gameMode,
              'score': score,
              'moves': moves,
              'secondsElapsed': secondsElapsed,
              'timeLimit': timeLimit,
              'coinsEarned': rewards.coins,
              'xpEarned': rewards.xp,
              'won': won,
              'playedAt': (playedAt ?? _now()).millisecondsSinceEpoch,
              'levelNumber': levelNumber,
            },
            'deltas': {
              'totalXp': rewards.xp,
              'totalCoins': rewards.coins,
              'totalMoves': moves,
              'gamesWon': won ? 1 : 0,
            },
            if (updated != null)
              'streak': {
                'currentStreak': updated.currentStreak,
                'longestStreak': updated.longestStreak,
                'lastPlayedDate': updated.lastPlayedDate,
              },
            if (won && levelNumber != null)
              'level': {'levelNumber': levelNumber, 'bestScore': score},
          },
        ),
        now: _now(),
      );

      return true;
    });
  }

  /// La última partida del jugador, o null si aún no ha jugado ninguna.
  Stream<MatchRow?> watchLastMatch(String playerLocalId) {
    return (_db.select(_db.matches)
          ..where((m) => m.playerLocalId.equals(playerLocalId))
          ..orderBy([(m) => OrderingTerm.desc(m.playedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  /// Historial reciente, de la más nueva a la más vieja.
  ///
  /// Consulta local con índice: no descarga nada ni cuesta lecturas.
  Stream<List<MatchRow>> watchRecentMatches(
    String playerLocalId, {
    int limit = 20,
  }) {
    return (_db.select(_db.matches)
          ..where((m) => m.playerLocalId.equals(playerLocalId))
          ..orderBy([(m) => OrderingTerm.desc(m.playedAt)])
          ..limit(limit))
        .watch();
  }
}
