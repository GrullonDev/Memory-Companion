import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/game/board/category/board_factory.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';
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

      expect(created.rounds, 3);
      expect(created.game, DuelGame.memory);
      for (var round = 0; round < 3; round++) {
        await repository.submitRound(
          duelId: created.id,
          uid: 'alice',
          round: round,
          score: fast,
        );
      }
      await repository.submitRound(
        duelId: created.id,
        uid: 'bob',
        round: 0,
        score: const DuelScore(score: 950, seconds: 60, moves: 12),
      );
      var live = await repository.watchDuel(created.id).first;
      expect(live?.status, DuelStatus.pending, reason: '1-0, falta decidir');
      expect(live?.nextRoundFor('bob'), 1);

      await repository.submitRound(
        duelId: created.id,
        uid: 'bob',
        round: 1,
        score: const DuelScore(score: 950, seconds: 60, moves: 12),
      );
      live = await repository.watchDuel(created.id).first;
      expect(live?.status, DuelStatus.completed, reason: '2-0 decide');
      expect(live?.outcomeFor('bob'), DuelOutcome.won);
      expect(live?.nextRoundFor('bob'), isNull, reason: 'la tercera sobra');
      bobs = await repository.watchDuels('bob').first;
      expect(bobs.single.resultOf('alice')?.score, 2700);
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

  group('serie al mejor de tres', () {
    const hi = DuelScore(score: 900, seconds: 30, moves: 8);
    const lo = DuelScore(score: 500, seconds: 30, moves: 8);

    Duel series(Map<String, Map<int, DuelScore>> rounds) =>
        Duel.fromFirestore('s', {
          'challengerUid': 'alice',
          'opponentUid': 'bob',
          'status': 'pending',
          'seed': 5,
          'gameId': 'digits',
          'rounds': 3,
          'roundResults': {
            for (final player in rounds.entries)
              player.key: {
                for (final round in player.value.entries)
                  '${round.key}': round.value.toMap(),
              },
          },
        });

    test('1-1 obliga a jugar la tercera', () {
      final duel = series({
        'alice': {0: hi, 1: lo},
        'bob': {0: lo, 1: hi},
      });
      expect(duel.game, DuelGame.digits);
      expect(duel.isDecided, isFalse);
      expect(duel.nextRoundFor('alice'), 2);
      expect(duel.outcomeFor('alice'), isNull);
    });

    test('la tercera ronda decide', () {
      final duel = series({
        'alice': {0: hi, 1: lo, 2: hi},
        'bob': {0: lo, 1: hi, 2: lo},
      });
      expect(duel.status, DuelStatus.completed);
      expect(duel.winsOf('alice'), 2);
      expect(duel.outcomeFor('alice'), DuelOutcome.won);
      expect(duel.outcomeFor('bob'), DuelOutcome.lost);
    });

    test('con las rondas igualadas, desempatan los puntos', () {
      final duel = series({
        'alice': {0: hi, 1: hi, 2: lo},
        'bob': {0: hi, 1: hi, 2: hi},
      });
      expect(duel.winsOf('alice'), 0);
      expect(duel.winsOf('bob'), 1);
      expect(duel.outcomeFor('bob'), DuelOutcome.won);
    });

    test('un duelo antiguo sigue siendo de una ronda en el tablero', () {
      final legacy = Duel.fromFirestore('l', {
        'challengerUid': 'alice',
        'opponentUid': 'bob',
        'status': 'pending',
        'results': {'alice': hi.toMap(), 'bob': lo.toMap()},
      });
      expect(legacy.isSeries, isFalse);
      expect(legacy.rounds, 1);
      expect(legacy.game, DuelGame.memory);
      expect(legacy.outcomeFor('alice'), DuelOutcome.won);
    });

    test('cada ronda se reparte distinto, igual para los dos', () {
      final duel = series(const {});
      expect(duel.seedFor(0), duel.seed);
      expect(duel.seedFor(1), isNot(duel.seedFor(0)));
      expect(duel.boardFor(1), duel.boardFor(1));
    });
  });
}
