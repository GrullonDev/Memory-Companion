import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_operation.dart';
import 'package:memory_companion/core/sync/sync_queue.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';
import 'package:memory_companion/features/player/model/player_streak.dart';

/// Dueño de la identidad del jugador en este dispositivo.
///
/// Un dispositivo tiene **exactamente un** perfil local. Se crea la primera
/// vez que se abre la app, sin red, sin cuenta y sin preguntar nada, y a
/// partir de ahí es la identidad estable a la que se cuelga todo el
/// progreso.
///
/// Deliberadamente **no** usa `signInAnonymously()` de Firebase: eso exigiría
/// red justo en el arranque inicial —el momento que más queremos blindar— y
/// ataría la identidad local a un servicio que debe ser opcional.
class PlayerRepository {
  PlayerRepository({
    required AppDatabase database,
    required SyncQueue syncQueue,
    String Function()? idGenerator,
    DateTime Function()? clock,
  })  : _db = database,
        _syncQueue = syncQueue,
        _newId = idGenerator ?? _defaultIdGenerator,
        _now = clock ?? DateTime.now;

  static String _defaultIdGenerator() => const Uuid().v4();

  final AppDatabase _db;
  final SyncQueue _syncQueue;
  final String Function() _newId;
  final DateTime Function() _now;

  /// Devuelve el perfil local, creándolo si es el primer arranque.
  ///
  /// Idempotente y segura frente a llamadas concurrentes: la lectura y la
  /// inserción ocurren en la misma transacción, así que dos invocaciones
  /// simultáneas no pueden acabar en dos identidades distintas.
  Future<PlayerProfile> ensureLocalProfile() {
    return _db.transaction(() async {
      final existing = await _selectFirst();
      if (existing != null) return PlayerProfile.fromRow(existing);

      final createdAt = _now().millisecondsSinceEpoch;
      final row = await _db.into(_db.playerProfiles).insertReturning(
            PlayerProfilesCompanion.insert(
              localId: _newId(),
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
      return PlayerProfile.fromRow(row);
    });
  }

  /// Lee el perfil sin crearlo. Null solo antes del primer arranque.
  Future<PlayerProfile?> readLocalProfile() async {
    final row = await _selectFirst();
    return row == null ? null : PlayerProfile.fromRow(row);
  }

  /// Emite el perfil cada vez que cambia.
  ///
  /// Es la fuente que observará la Home: un stream de SQLite, sin red de por
  /// medio, que se actualiza solo cuando algo escribe en la tabla.
  Stream<PlayerProfile?> watchLocalProfile() {
    return (_db.select(_db.playerProfiles)..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null ? null : PlayerProfile.fromRow(row));
  }

  /// Vincula el perfil local a una cuenta de Firebase.
  ///
  /// No copia, no migra y no borra: escribe [cloudUid] sobre la fila que ya
  /// existía. Ese es el motivo de que vincular no pueda perder progreso.
  Future<void> linkToCloud({
    required String localId,
    required String cloudUid,
  }) async {
    await (_db.update(_db.playerProfiles)
          ..where((p) => p.localId.equals(localId)))
        .write(
      PlayerProfilesCompanion(
        cloudUid: Value(cloudUid),
        updatedAt: Value(_now().millisecondsSinceEpoch),
        version: const Value.absent(),
      ),
    );
  }

  /// Cambia nombre y/o avatar, subiendo [PlayerProfile.version].
  ///
  /// La versión sube porque estos campos no son acumulables: si dos
  /// dispositivos los cambian offline, el conflicto se resuelve con el
  /// contador, no sumando.
  Future<void> updateIdentity({
    required String localId,
    String? displayName,
    int? avatarSeed,
  }) async {
    if (displayName == null && avatarSeed == null) return;

    await _db.transaction(() async {
      final current = await _selectById(localId);
      if (current == null) return;

      await (_db.update(_db.playerProfiles)
            ..where((p) => p.localId.equals(localId)))
          .write(
        PlayerProfilesCompanion(
          displayName: displayName == null
              ? const Value.absent()
              : Value(displayName),
          avatarSeed:
              avatarSeed == null ? const Value.absent() : Value(avatarSeed),
          updatedAt: Value(_now().millisecondsSinceEpoch),
          version: Value(current.version + 1),
        ),
      );

      // La identidad no es acumulable: viaja con su versión, y el conflicto
      // se resuelve comparando contadores, no sumando.
      await _enqueue(
        localId,
        type: SyncOperationType.upsertProfile,
        entityType: 'player',
        payload: {
          'displayName': ?displayName,
          'avatarSeed': ?avatarSeed,
          'version': current.version + 1,
        },
      );
    });
  }

  /// Suma monedas ganadas y devuelve el saldo resultante.
  ///
  /// Escribe en local y punto: sin red, sin cuenta y sin esperar a nadie.
  Future<int> earnCoins({required String localId, required int amount}) {
    return _db.transaction(() async {
      final current = await _selectById(localId);
      if (current == null) return 0;
      if (amount <= 0) return current.totalCoins;

      final next = current.totalCoins + amount;
      await _writeProfile(
        localId,
        PlayerProfilesCompanion(totalCoins: Value(next)),
      );
      // Se encola el **delta**, no el total: dos dispositivos sin conexión
      // convergen sumando en lugar de pisarse.
      await _enqueue(
        localId,
        type: SyncOperationType.earnCoins,
        entityType: 'player',
        payload: {'totalCoins': amount},
      );
      return next;
    });
  }

  /// Gasta monedas. Devuelve `false` —**sin tocar nada**— si no alcanza.
  ///
  /// La comprobación y la escritura ocurren en la misma transacción, así que
  /// dos compras simultáneas no pueden dejar el saldo en negativo.
  Future<bool> spendCoins({
    required String localId,
    required int amount,
  }) {
    return _db.transaction(() async {
      if (amount < 0) return false;
      if (amount == 0) return true;

      final current = await _selectById(localId);
      if (current == null || current.totalCoins < amount) return false;

      await _writeProfile(
        localId,
        PlayerProfilesCompanion(totalCoins: Value(current.totalCoins - amount)),
      );
      await _enqueue(
        localId,
        type: SyncOperationType.spendCoins,
        entityType: 'player',
        payload: {'totalCoins': -amount},
      );
      return true;
    });
  }

  /// Aplica el resultado de una partida a los acumulados del jugador.
  ///
  /// Un único sitio suma XP, monedas, movimientos y victorias, de modo que no
  /// puedan divergir. Todos los sumandos son **incrementos**, nunca totales:
  /// es lo que permitirá sincronizarlos con `FieldValue.increment` sin que un
  /// dispositivo pise el progreso del otro.
  ///
  /// La llama [LocalMatchRepository] dentro de la transacción que inserta la
  /// partida, para que premio y registro caigan juntos o no caigan.
  Future<void> applyMatchOutcome({
    required String localId,
    required int coinsEarned,
    required int xpEarned,
    required int movesUsed,
    required bool won,
  }) {
    return _db.transaction(() async {
      final current = await _selectById(localId);
      if (current == null) return;

      // Jugar una partida es lo que sostiene la racha. Se resuelve aquí, en
      // la misma escritura que los acumulados, para que no puedan divergir.
      final streak = advanceStreak(
        lastPlayedDate: current.lastPlayedDate,
        currentStreak: current.currentStreak,
        longestStreak: current.longestStreak,
        now: _now(),
      );

      await _writeProfile(
        localId,
        PlayerProfilesCompanion(
          // Los acumulados son monótonos: un valor negativo se ignora en vez
          // de restar, porque nada en el juego debe poder quitarte XP.
          totalXp: Value(current.totalXp + (xpEarned < 0 ? 0 : xpEarned)),
          totalCoins:
              Value(current.totalCoins + (coinsEarned < 0 ? 0 : coinsEarned)),
          totalMoves:
              Value(current.totalMoves + (movesUsed < 0 ? 0 : movesUsed)),
          gamesWon: Value(current.gamesWon + (won ? 1 : 0)),
          currentStreak: Value(streak.currentStreak),
          longestStreak: Value(streak.longestStreak),
          lastPlayedDate: Value(streak.lastPlayedDate),
        ),
      );
    });
  }

  /// Registra actividad del día sin que medie una partida.
  ///
  /// La usará el reto diario, que cuenta para la racha aunque no genere una
  /// fila en `matches`.
  Future<StreakUpdate?> registerPlayedToday({required String localId}) {
    return _db.transaction(() async {
      final current = await _selectById(localId);
      if (current == null) return null;

      final streak = advanceStreak(
        lastPlayedDate: current.lastPlayedDate,
        currentStreak: current.currentStreak,
        longestStreak: current.longestStreak,
        now: _now(),
      );
      if (!streak.changed) return streak;

      await _writeProfile(
        localId,
        PlayerProfilesCompanion(
          currentStreak: Value(streak.currentStreak),
          longestStreak: Value(streak.longestStreak),
          lastPlayedDate: Value(streak.lastPlayedDate),
        ),
      );
      await _enqueue(
        localId,
        type: SyncOperationType.updateStreak,
        entityType: 'player',
        payload: {
          'currentStreak': streak.currentStreak,
          'longestStreak': streak.longestStreak,
          'lastPlayedDate': streak.lastPlayedDate,
        },
      );
      return streak;
    });
  }

  /// Encola una operación dentro de la transacción en curso.
  Future<void> _enqueue(
    String localId, {
    required SyncOperationType type,
    required String entityType,
    required Map<String, Object?> payload,
  }) {
    return _syncQueue.enqueue(
      SyncOperationInput(
        opId: _newId(),
        playerLocalId: localId,
        type: type,
        entityType: entityType,
        entityId: localId,
        payload: payload,
      ),
      now: _now(),
    );
  }

  /// Escritura con marca de tiempo, para no repetir `updatedAt` en cada sitio.
  Future<void> _writeProfile(
    String localId,
    PlayerProfilesCompanion companion,
  ) {
    return (_db.update(_db.playerProfiles)
          ..where((p) => p.localId.equals(localId)))
        .write(
      companion.copyWith(updatedAt: Value(_now().millisecondsSinceEpoch)),
    );
  }

  Future<PlayerProfileRow?> _selectFirst() {
    return (_db.select(_db.playerProfiles)..limit(1)).getSingleOrNull();
  }

  Future<PlayerProfileRow?> _selectById(String localId) {
    return (_db.select(_db.playerProfiles)
          ..where((p) => p.localId.equals(localId)))
        .getSingleOrNull();
  }
}
