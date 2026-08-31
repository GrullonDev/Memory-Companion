import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/player/model/player_profile.dart';

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
    String Function()? idGenerator,
    DateTime Function()? clock,
  })  : _db = database,
        _newId = idGenerator ?? _defaultIdGenerator,
        _now = clock ?? DateTime.now;

  static String _defaultIdGenerator() => const Uuid().v4();

  final AppDatabase _db;
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
    });
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
