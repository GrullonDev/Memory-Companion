import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:memory_companion/features/versus/model/duel.dart';

/// Versus duels, in Firestore. Like friends, they only exist in the cloud:
/// a duel is shared between two devices by definition.
class DuelRepository {
  DuelRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _duels =>
      _firestore.collection('duels');

  /// How many duels the Versus screen keeps, newest first.
  static const int historyLimit = 30;

  Future<Duel> create({
    required String challengerUid,
    required String opponentUid,
    required String friendshipId,
    required int seed,
    required String categoryId,
    required String languageCode,
  }) async {
    final ref = _duels.doc();
    await ref.set({
      'challengerUid': challengerUid,
      'opponentUid': opponentUid,
      'members': [challengerUid, opponentUid],
      'friendshipId': friendshipId,
      'seed': seed,
      'categoryId': categoryId,
      'languageCode': languageCode,
      'status': 'pending',
      'results': <String, Object>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Duel(
      id: ref.id,
      challengerUid: challengerUid,
      opponentUid: opponentUid,
      friendshipId: friendshipId,
      seed: seed,
      categoryId: categoryId,
      languageCode: languageCode,
      status: DuelStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// Every duel [uid] is part of, newest first.
  ///
  /// Sorted here rather than with `orderBy`, which together with
  /// `arrayContains` would need a composite index.
  Stream<List<Duel>> watchDuels(String uid) {
    return _duels.where('members', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final duels = [
        for (final doc in snapshot.docs) Duel.fromFirestore(doc.id, doc.data()),
      ];
      final epoch = DateTime.fromMillisecondsSinceEpoch(0);
      duels.sort(
        (a, b) => (b.createdAt ?? epoch).compareTo(a.createdAt ?? epoch),
      );
      return duels.take(historyLimit).toList();
    });
  }

  Stream<Duel?> watchDuel(String id) {
    return _duels.doc(id).snapshots().map((doc) {
      final data = doc.data();
      return data == null ? null : Duel.fromFirestore(doc.id, data);
    });
  }

  /// Records [uid]'s result.
  ///
  /// A plain update rather than a transaction, so Firestore queues it when
  /// the player finishes offline. The first result per player stands —
  /// playing the board again would be playing it from memory — and the
  /// security rules refuse to overwrite it.
  Future<void> submitResult({
    required String duelId,
    required String uid,
    required DuelScore score,
  }) {
    return _duels.doc(duelId).update({
      'results.$uid': score.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Opens a room: a duel with no opponent yet, which anyone holding
  /// [roomCode] can join. The host can play it straight away.
  Future<Duel> createRoom({
    required String hostUid,
    required String hostName,
    required String roomCode,
    required int seed,
    required String categoryId,
    required String languageCode,
  }) async {
    final ref = _duels.doc();
    await ref.set({
      'challengerUid': hostUid,
      'opponentUid': '',
      'members': [hostUid],
      'friendshipId': '',
      'roomCode': roomCode,
      'names': {hostUid: hostName},
      'seed': seed,
      'categoryId': categoryId,
      'languageCode': languageCode,
      'status': 'open',
      'results': <String, Object>{},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return Duel(
      id: ref.id,
      challengerUid: hostUid,
      opponentUid: '',
      friendshipId: '',
      seed: seed,
      categoryId: categoryId,
      languageCode: languageCode,
      status: DuelStatus.open,
      createdAt: DateTime.now(),
      roomCode: roomCode,
      names: {hostUid: hostName},
    );
  }

  /// The open room with [roomCode], if there is one.
  Future<Duel?> findOpenRoom(String roomCode) async {
    final query = await _duels
        .where('roomCode', isEqualTo: roomCode)
        .where('status', isEqualTo: 'open')
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.single;
    return Duel.fromFirestore(doc.id, doc.data());
  }

  /// Takes the free seat in [room]. A transaction, so two players entering
  /// the same code at once cannot both become the opponent.
  ///
  /// Returns the joined duel, or null if someone got there first.
  Future<Duel?> joinRoom({
    required Duel room,
    required String uid,
    required String name,
  }) {
    final ref = _duels.doc(room.id);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || data['status'] != 'open') return null;
      final host = data['challengerUid'] as String? ?? '';
      transaction.update(ref, {
        'opponentUid': uid,
        'members': [host, uid],
        'status': 'pending',
        'names.$uid': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return Duel.fromFirestore(room.id, {
        ...data,
        'opponentUid': uid,
        'members': [host, uid],
        'status': 'pending',
        'names': {...?(data['names'] as Map?), uid: name},
      });
    });
  }

  /// The opponent turns the challenge down.
  Future<void> decline(String duelId) {
    return _duels.doc(duelId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
