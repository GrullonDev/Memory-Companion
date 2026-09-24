import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game/board/category/board_factory.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/repository/duel_repository.dart';

void main() {
  const fast = DuelScore(score: 900, seconds: 40, moves: 10);

  group('DuelScore', () {
    test(
      'gana más puntos; con empate, el más rápido; luego menos movimientos',
      () {
        expect(
          fast.compareTo(const DuelScore(score: 800, seconds: 10, moves: 6)),
          1,
        );
        expect(
          fast.compareTo(const DuelScore(score: 900, seconds: 50, moves: 6)),
          1,
        );
        expect(
          fast.compareTo(const DuelScore(score: 900, seconds: 40, moves: 12)),
          1,
        );
        expect(fast.compareTo(fast), 0);
      },
    );
  });

  group('Duel', () {
    Duel duel({Map<String, dynamic> results = const {}, String? status}) =>
        Duel.fromFirestore('d1', {
          'challengerUid': 'alice',
          'opponentUid': 'bob',
          'friendshipId': 'alice_bob',
          'seed': 1234,
          'categoryId': GameCategories.numeric.id,
          'languageCode': 'es',
          'status': ?status,
          'results': results,
        });

    test('se completa cuando los dos jugaron', () {
      final pending = duel(results: {'alice': fast.toMap()});
      expect(pending.status, DuelStatus.pending);
      expect(pending.awaitsTurnOf('bob'), isTrue);
      expect(pending.isInvitationFor('bob'), isTrue);
      expect(pending.awaitsTurnOf('alice'), isFalse);
      expect(pending.outcomeFor('alice'), isNull);

      final done = duel(
        results: {
          'alice': fast.toMap(),
          'bob': const DuelScore(score: 700, seconds: 30, moves: 9).toMap(),
        },
      );
      expect(done.status, DuelStatus.completed);
      expect(done.outcomeFor('alice'), DuelOutcome.won);
      expect(done.outcomeFor('bob'), DuelOutcome.lost);
      expect(done.awaitsTurnOf('bob'), isFalse);
    });

    test('un reto rechazado ya no espera a nadie', () {
      final declined = duel(status: 'declined');
      expect(declined.status, DuelStatus.declined);
      expect(declined.awaitsTurnOf('bob'), isFalse);
      expect(declined.outcomeFor('bob'), isNull);
    });

    test('los dos lados reciben exactamente el mismo tablero', () {
      final board = duel().board;
      List<String> deal() => [
        for (final card in BoardFactory.deal(
          category: board.category,
          settings: board.settings,
          languageCode: 'es',
          random: board.random,
        ))
          card.pairId,
      ];

      expect(board.category, GameCategories.numeric);
      expect(board.settings.pairCount, Duel.pairCount);
      expect(deal(), deal());
    });
  });

  group('DuelRepository', () {
    late DuelRepository repository;

    setUp(
      () => repository = DuelRepository(firestore: FakeFirebaseFirestore()),
    );

    Future<Duel> create() => repository.create(
      challengerUid: 'alice',
      opponentUid: 'bob',
      friendshipId: 'alice_bob',
      seed: 42,
      categoryId: GameCategories.classic.id,
      languageCode: 'en',
    );

    test('crear, jugar los dos y completar', () async {
      final created = await create();
      expect(created.status, DuelStatus.pending);

      var bobs = await repository.watchDuels('bob').first;
      expect(bobs.single.id, created.id);
      expect(bobs.single.seed, 42);
      expect(bobs.single.isInvitationFor('bob'), isTrue);

      await repository.submitResult(
        duelId: created.id,
        uid: 'alice',
        score: fast,
      );
      await repository.submitResult(
        duelId: created.id,
        uid: 'bob',
        score: const DuelScore(score: 950, seconds: 60, moves: 12),
      );

      final finished = await repository.watchDuel(created.id).first;
      expect(finished?.status, DuelStatus.completed);
      expect(finished?.outcomeFor('bob'), DuelOutcome.won);
      bobs = await repository.watchDuels('bob').first;
      expect(bobs.single.resultOf('alice')?.score, 900);
    });

    test('rechazar', () async {
      final created = await create();
      await repository.decline(created.id);
      final declined = await repository.watchDuel(created.id).first;
      expect(declined?.status, DuelStatus.declined);
    });

    test('los duelos llegan del más nuevo al más viejo', () async {
      final first = await create();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = await create();
      final duels = await repository.watchDuels('alice').first;
      expect([for (final d in duels) d.id], [second.id, first.id]);
      expect(await repository.watchDuels('carol').first, isEmpty);
    });
  });
}
