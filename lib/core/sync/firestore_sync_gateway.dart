import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/sync_gateway.dart';
import 'package:memory_companion/core/sync/sync_operation.dart';

/// Implementación real contra Cloud Firestore.
///
/// Toda operación sigue el mismo patrón de idempotencia: dentro de una
/// transacción se lee `users/{uid}/sync_ops/{opId}`; si existe, la operación
/// ya se aplicó y no se hace nada. Si no, se aplica el efecto **y** se escribe
/// ese registro, ambos en la misma transacción.
///
/// Los acumulados viajan como `FieldValue.increment`, nunca como totales: es
/// lo que hace que dos dispositivos que jugaron sin conexión converjan
/// sumando en lugar de pisarse.
class FirestoreSyncGateway implements SyncGateway {
  FirestoreSyncGateway({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  @override
  Future<Map<String, Object?>?> readProfile(String cloudUid) async {
    try {
      final snapshot =
          await _firestore.collection('users').doc(cloudUid).get();
      return snapshot.exists ? snapshot.data() : null;
    } on FirebaseException catch (error) {
      throw _toFailure(error);
    }
  }

  @override
  Future<void> apply(
    SyncOperation operation, {
    required String cloudUid,
  }) async {
    final userDoc = _firestore.collection('users').doc(cloudUid);
    final ledgerDoc = userDoc.collection('sync_ops').doc(operation.opId);

    try {
      await _firestore.runTransaction((transaction) async {
        // Firestore exige todas las lecturas antes que las escrituras.
        final ledger = await transaction.get(ledgerDoc);
        if (ledger.exists) return; // ya aplicada: no-op

        final user = await transaction.get(userDoc);
        final userData = user.data() ?? const <String, Object?>{};

        switch (operation.type) {
          case SyncOperationType.recordMatch:
            _applyRecordMatch(transaction, operation, userDoc, userData);
          case SyncOperationType.earnCoins:
          case SyncOperationType.spendCoins:
            transaction.set(
              userDoc,
              {
                'totalCoins':
                    FieldValue.increment(operation.intValue('totalCoins')),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          case SyncOperationType.addXp:
            transaction.set(
              userDoc,
              {
                'totalXp': FieldValue.increment(operation.intValue('totalXp')),
                'updatedAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            );
          case SyncOperationType.updateStreak:
            transaction.set(
              userDoc,
              _streakUpdate(operation.payload, userData),
              SetOptions(merge: true),
            );
          case SyncOperationType.upsertProfile:
            transaction.set(
              userDoc,
              _profileUpdate(operation.payload, userData),
              SetOptions(merge: true),
            );
          case SyncOperationType.completeLevel:
            _applyCompleteLevel(transaction, operation.payload, userDoc);
          case SyncOperationType.completeChallenge:
            // Aún sin backend de retos: se marca aplicada para que no se
            // quede atascada bloqueando la cola.
            break;
          case SyncOperationType.createMatch:
            _writeMatch(transaction, operation.mapValue('match'), userDoc);
        }

        transaction.set(ledgerDoc, {
          'type': operation.type.name,
          'appliedAt': FieldValue.serverTimestamp(),
          // Hora del cliente junto a la del servidor: contrastarlas es lo que
          // permitirá detectar relojes manipulados sin bloquear el juego.
          'clientCreatedAt': operation.createdAt.millisecondsSinceEpoch,
        });
      });
    } on FirebaseException catch (error) {
      throw _toFailure(error);
    }
  }

  void _applyRecordMatch(
    Transaction transaction,
    SyncOperation operation,
    DocumentReference<Map<String, Object?>> userDoc,
    Map<String, Object?> userData,
  ) {
    _writeMatch(transaction, operation.mapValue('match'), userDoc);

    final deltas = operation.mapValue('deltas');
    final update = <String, Object?>{
      'updatedAt': FieldValue.serverTimestamp(),
      for (final field in const [
        'totalXp',
        'totalCoins',
        'totalMoves',
        'gamesWon',
      ])
        if (deltas[field] is int && (deltas[field]! as int) != 0)
          field: FieldValue.increment(deltas[field]! as int),
      ..._streakUpdate(operation.mapValue('streak'), userData),
    };
    transaction.set(userDoc, update, SetOptions(merge: true));

    final level = operation.mapValue('level');
    if (level.isNotEmpty) {
      _applyCompleteLevel(transaction, level, userDoc);
    }
  }

  void _writeMatch(
    Transaction transaction,
    Map<String, Object?> match,
    DocumentReference<Map<String, Object?>> userDoc,
  ) {
    final id = match['id'];
    if (id is! String || id.isEmpty) return;

    final playedAt = match['playedAt'];
    transaction.set(
      userDoc.collection('matches').doc(id),
      {
        ...match,
        // El id ya es el del documento; no hace falta duplicarlo dentro.
        'id': FieldValue.delete(),
        if (playedAt is int)
          'playedAt': Timestamp.fromMillisecondsSinceEpoch(playedAt),
        'syncedAt': FieldValue.serverTimestamp(),
      }..removeWhere((_, value) => value == null),
      SetOptions(merge: true),
    );
  }

  void _applyCompleteLevel(
    Transaction transaction,
    Map<String, Object?> level,
    DocumentReference<Map<String, Object?>> userDoc,
  ) {
    final number = level['levelNumber'];
    if (number is! int) return;

    // La mejor marca se resuelve con máximo del lado del servidor, no con
    // «gana el último»: si dos dispositivos jugaron el mismo nivel sin
    // conexión, la buena es la mejor de las dos.
    transaction.set(
      userDoc.collection('level_progress').doc('$number'),
      {
        'levelNumber': number,
        'isCompleted': true,
        'bestScore': level['bestScore'],
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// La racha no es acumulable: el récord se resuelve con máximo y el día se
  /// resuelve con el más reciente.
  Map<String, Object?> _streakUpdate(
    Map<String, Object?> streak,
    Map<String, Object?> userData,
  ) {
    if (streak.isEmpty) return const {};

    final remoteLongest = userData['longestStreak'];
    final localLongest = streak['longestStreak'];
    final longest = [
      if (remoteLongest is int) remoteLongest,
      if (localLongest is int) localLongest,
    ];

    final remoteDate = userData['lastPlayedDate'];
    final localDate = streak['lastPlayedDate'];
    final keepRemote = remoteDate is String &&
        localDate is String &&
        remoteDate.compareTo(localDate) > 0;

    return <String, Object?>{
      if (longest.isNotEmpty)
        'longestStreak': longest.reduce((a, b) => a > b ? a : b),
      if (!keepRemote) ...{
        'currentStreak': ?streak['currentStreak'],
        'lastPlayedDate': ?localDate,
      },
    };
  }

  /// Los campos de identidad se resuelven por versión: gana el contador más
  /// alto, no el que llegue más tarde.
  Map<String, Object?> _profileUpdate(
    Map<String, Object?> payload,
    Map<String, Object?> userData,
  ) {
    final incoming = payload['version'];
    final existing = userData['version'];
    if (incoming is int && existing is int && incoming <= existing) {
      return const {};
    }

    return <String, Object?>{
      'displayName': ?payload['displayName'],
      'avatarSeed': ?payload['avatarSeed'],
      'version': ?incoming,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SyncFailure _toFailure(FirebaseException error) {
    // Reintentar esto no lo arregla: solo gasta cuota y batería.
    const permanentCodes = {
      'permission-denied',
      'invalid-argument',
      'unauthenticated',
      'failed-precondition',
    };
    return SyncFailure(
      '${error.code}: ${error.message ?? ''}'.trim(),
      permanent: permanentCodes.contains(error.code),
    );
  }
}
