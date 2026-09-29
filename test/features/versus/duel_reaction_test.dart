import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_reaction.dart';
import 'package:memory_companion/features/versus/repository/duel_repository.dart';
import 'package:memory_companion/features/versus/widget/duel_reactions.dart';

void main() {
  group('DuelReactionEvent', () {
    test('se lee del duelo por jugador', () {
      final duel = Duel.fromFirestore('d1', {
        'challengerUid': 'alice',
        'opponentUid': 'bob',
        'gameId': 'memory',
        'reactions': {
          'bob': {'reaction': 'fire', 'seq': 7},
          'alice': {'reaction': 'nope', 'seq': 3},
        },
      });
      expect(duel.reactions['bob']?.reaction, DuelReaction.fire);
      expect(duel.reactions['bob']?.seq, 7);
      expect(
        duel.reactions.containsKey('alice'),
        isFalse,
        reason: 'una reacción desconocida no se muestra',
      );
    });

    test('sobrevive a withRound y withStatus', () {
      final duel = Duel.fromFirestore('d1', {
        'challengerUid': 'alice',
        'opponentUid': 'bob',
        'gameId': 'memory',
        'rounds': 3,
        'reactions': {
          'bob': {'reaction': 'laugh', 'seq': 1},
        },
      });
      final updated = duel.withRound(
        'alice',
        0,
        const DuelScore(score: 1, seconds: 1, moves: 1),
      );
      expect(updated.reactions['bob']?.reaction, DuelReaction.laugh);
    });
  });

  test('sendReaction escribe solo la reacción del jugador', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = DuelRepository(firestore: firestore);
    final duel = await repository.create(
      challengerUid: 'alice',
      opponentUid: 'bob',
      friendshipId: 'alice_bob',
      seed: 1,
      categoryId: 'animals',
      languageCode: 'es',
    );

    await repository.sendReaction(
      duelId: duel.id,
      uid: 'alice',
      reaction: const DuelReactionEvent(reaction: DuelReaction.wow, seq: 42),
    );

    final live = await repository.watchDuel(duel.id).first;
    expect(live!.reactions['alice']?.reaction, DuelReaction.wow);
    expect(live.reactions['alice']?.seq, 42);
    expect(live.reactions.containsKey('bob'), isFalse);
  });

  group('FloatingReactions', () {
    Widget host(DuelReactionEvent? event) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: FloatingReactions(
            event: event,
            child: const SizedBox.square(dimension: 40),
          ),
        ),
      ),
    );

    testWidgets('lo que ya estaba al aparecer no flota', (tester) async {
      await tester.pumpWidget(
        host(const DuelReactionEvent(reaction: DuelReaction.fire, seq: 1)),
      );
      expect(find.text('🔥'), findsNothing);
    });

    testWidgets('una reacción nueva flota y desaparece', (tester) async {
      await tester.pumpWidget(host(null));
      await tester.pumpWidget(
        host(const DuelReactionEvent(reaction: DuelReaction.fire, seq: 1)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('🔥'), findsOneWidget);

      // El mismo snapshot otra vez no repite la animación.
      await tester.pumpWidget(
        host(const DuelReactionEvent(reaction: DuelReaction.fire, seq: 1)),
      );
      expect(find.text('🔥'), findsOneWidget);

      await tester.pump(FloatingReactions.lifetime);
      await tester.pump();
      expect(find.text('🔥'), findsNothing);
    });
  });
}
