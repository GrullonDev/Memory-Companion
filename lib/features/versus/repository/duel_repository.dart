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

  /// The opponent turns the challenge down.
  Future<void> decline(String duelId) {
    return _duels.doc(duelId).update({
      'status': 'declined',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
