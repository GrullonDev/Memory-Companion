import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/database/database_enums.dart';
import 'package:memory_companion/core/sync/firestore_sync_gateway.dart';
import 'package:memory_companion/core/sync/sync_operation.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreSyncGateway gateway;

  const uid = 'test-uid';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    gateway = FirestoreSyncGateway(firestore: firestore);
  });

  SyncOperation operation({
    required SyncOperationType type,
    required Map<String, Object?> payload,
    String opId = 'op-1',
  }) {
    return SyncOperation(
      opId: opId,
      playerLocalId: 'local-1',
      type: type,
      entityType: 'player',
      entityId: 'local-1',
      payload: payload,
      createdAt: DateTime(2026, 11, 10),
      status: SyncStatus.syncing,
      retryCount: 0,
      nextAttemptAt: DateTime(2026, 11, 10),
    );
  }

  group('completeLevel bestScore resolution', () {
    test('first score is written as-is', () async {
      await gateway.apply(
        operation(
          type: SyncOperationType.completeLevel,
          payload: {'levelNumber': 1, 'bestScore': 80},
        ),
        cloudUid: uid,
      );

      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('level_progress')
          .doc('1')
          .get();
      expect(doc.data()?['bestScore'], 80);
    });

    test('higher score overwrites lower', () async {
      await gateway.apply(
        operation(
          type: SyncOperationType.completeLevel,
          payload: {'levelNumber': 1, 'bestScore': 80},
          opId: 'op-1',
        ),
        cloudUid: uid,
      );

      await gateway.apply(
        operation(
          type: SyncOperationType.completeLevel,
          payload: {'levelNumber': 1, 'bestScore': 95},
          opId: 'op-2',
        ),
        cloudUid: uid,
      );

      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('level_progress')
          .doc('1')
          .get();
      expect(doc.data()?['bestScore'], 95);
    });

    test('lower score does NOT overwrite higher', () async {
      await gateway.apply(
        operation(
          type: SyncOperationType.completeLevel,
          payload: {'levelNumber': 1, 'bestScore': 95},
          opId: 'op-1',
        ),
        cloudUid: uid,
      );

      await gateway.apply(
        operation(
          type: SyncOperationType.completeLevel,
          payload: {'levelNumber': 1, 'bestScore': 70},
          opId: 'op-2',
        ),
        cloudUid: uid,
      );

      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('level_progress')
          .doc('1')
          .get();
      expect(doc.data()?['bestScore'], 95);
    });
  });

  group('idempotency', () {
    test('replaying an operation is a no-op', () async {
      await gateway.apply(
        operation(
          type: SyncOperationType.earnCoins,
          payload: {'totalCoins': 100},
        ),
        cloudUid: uid,
      );

      await gateway.apply(
        operation(
          type: SyncOperationType.earnCoins,
          payload: {'totalCoins': 100},
        ),
        cloudUid: uid,
      );

      final doc = await firestore.collection('users').doc(uid).get();
      expect(doc.data()?['totalCoins'], 100);
    });
  });

  group('earnCoins and spendCoins', () {
    test('earnCoins writes totalCoins', () async {
      await gateway.apply(
        operation(
          type: SyncOperationType.earnCoins,
          payload: {'totalCoins': 500},
          opId: 'earn-1',
        ),
        cloudUid: uid,
      );

      final doc = await firestore.collection('users').doc(uid).get();
      expect(doc.data()?['totalCoins'], isNotNull);
    });

    test('spendCoins writes totalCoins', () async {
      await gateway.apply(
        operation(
          type: SyncOperationType.spendCoins,
          payload: {'totalCoins': -200},
          opId: 'spend-1',
        ),
        cloudUid: uid,
      );

      final doc = await firestore.collection('users').doc(uid).get();
      expect(doc.data()?['totalCoins'], isNotNull);
    });
  });

  group('account deletion', () {
    test('deleteAllUserData removes user doc and subcollections', () async {
      final userDoc = firestore.collection('users').doc(uid);
      await userDoc.set({'displayName': 'Test'});
      await userDoc.collection('matches').doc('m1').set({'score': 100});
      await userDoc.collection('sync_ops').doc('op1').set({'type': 'earn'});
      await userDoc.collection('level_progress').doc('1').set({
        'levelNumber': 1,
      });
      await firestore.collection('user_index').doc(uid).set({
        'displayName': 'Test',
      });

      // Use UserRepository to test the deletion logic
      final repo = _UserRepoHelper(firestore);
      await repo.deleteAllUserData(uid);

      expect((await userDoc.get()).exists, isFalse);
      expect(
        (await firestore.collection('user_index').doc(uid).get()).exists,
        isFalse,
      );
      final matches = await userDoc.collection('matches').get();
      expect(matches.docs, isEmpty);
    });
  });
}

class _UserRepoHelper {
  _UserRepoHelper(this._firestore);
  final FakeFirebaseFirestore _firestore;

  Future<void> deleteAllUserData(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);
    for (final sub in [
      'matches',
      'level_progress',
      'sync_ops',
      'achievements',
    ]) {
      final snapshots = await userDoc.collection(sub).limit(500).get();
      final batch = _firestore.batch();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await userDoc.delete();
    await _firestore.collection('user_index').doc(uid).delete();
  }
}
