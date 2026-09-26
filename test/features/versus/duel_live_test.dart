import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/game/board/model/board_state.dart';
import 'package:memory_companion/features/game/board/model/card_face.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/versus/duel_round_host.dart';
import 'package:memory_companion/features/versus/model/duel.dart';
import 'package:memory_companion/features/versus/model/duel_game.dart';
import 'package:memory_companion/features/versus/widget/opponent_mirror.dart';

BoardState _board(List<MemoryCard> cards, {int preview = 0}) => BoardState(
  matchId: 'm',
  cards: cards,
  totalSeconds: 90,
  secondsRemaining: 60,
  previewSecondsRemaining: preview,
);

List<MemoryCard> _cards({
  Set<int> up = const {},
  Set<int> matched = const {},
}) => [
  for (var i = 0; i < 4; i++)
    MemoryCard(
      id: i,
      pairId: '${i ~/ 2}',
      face: const SymbolFace('x'),
      isFaceUp: up.contains(i) || matched.contains(i),
      isMatched: matched.contains(i),
    ),
];

void main() {
  group('DuelRoundHost.boardProgress', () {
    test('una pareja encontrada es un acierto con sus cartas', () {
      final progress = DuelRoundHost.boardProgress(
        _board(_cards(up: {0, 1})),
        _board(_cards(matched: {0, 1})),
      );
      expect(progress.event, DuelEvent.hit);
      expect(progress.cards, [0, 1]);
      expect(progress.matched, [0, 1]);
      expect(progress.solved, 1);
      expect(progress.total, 2);
    });

    test('dos cartas que se tapan son un fallo, al taparse', () {
      final progress = DuelRoundHost.boardProgress(
        _board(_cards(up: {0, 2})),
        _board(_cards()),
      );
      expect(progress.event, DuelEvent.miss);
      expect(progress.cards, [0, 2]);
    });

    test('el final de la vista previa no es un fallo', () {
      final progress = DuelRoundHost.boardProgress(
        _board(_cards(up: {0, 1, 2, 3}), preview: 1),
        _board(_cards()),
      );
      expect(progress.event, DuelEvent.none);
    });

    test('voltear la primera carta no cuenta todavía', () {
      final progress = DuelRoundHost.boardProgress(
        _board(_cards()),
        _board(_cards(up: {3})),
      );
      expect(progress.event, DuelEvent.none);
    });
  });

  test('el informe viaja entero por Firestore', () {
    const sent = DuelProgress(
      round: 1,
      score: 640,
      solved: 3,
      total: 6,
      event: DuelEvent.miss,
      seq: 7,
      cards: [2, 9],
      matched: [0, 1, 4, 5, 6, 7],
    );
    final back = DuelProgress.fromMap(sent.toMap());
    expect(back.round, 1);
    expect(back.event, DuelEvent.miss);
    expect(back.seq, 7);
    expect(back.cards, [2, 9]);
    expect(back.matched, hasLength(6));
    expect(back.fraction, 0.5);
    expect(DuelProgress.fromMap(const {}).event, DuelEvent.none);
  });

  group('lo que ve el jugador del rival', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (call) async => call.method == 'getAll' ? <String, Object>{} : true,
          );
      await FlutterLocalization.instance.ensureInitialized();
      FlutterLocalization.instance.init(
        mapLocales: const [
          MapLocale('es', AppLocale.es),
          MapLocale('en', AppLocale.en),
        ],
        initLanguageCode: 'en',
      );
    });

    Future<void> pump(WidgetTester tester, DuelProgress? progress) {
      return tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FlutterLocalization.instance.supportedLocales,
          localizationsDelegates:
              FlutterLocalization.instance.localizationsDelegates,
          home: Scaffold(
            body: Column(
              children: [
                RivalEventBanner(
                  progress: progress,
                  rivalName: 'Bob',
                  game: DuelGame.memory,
                ),
                OpponentMirror(
                  game: DuelGame.memory,
                  rivalName: 'Bob',
                  progress: progress,
                  live: true,
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('cada jugada nueva del rival se anuncia una vez', (
      tester,
    ) async {
      const start = DuelProgress(round: 0, score: 0, seq: 1);
      await pump(tester, start);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bob found a pair!'), findsNothing, reason: 'ya vista');

      await pump(
        tester,
        const DuelProgress(
          round: 0,
          score: 500,
          seq: 2,
          event: DuelEvent.hit,
          cards: [0, 5],
          matched: [0, 5],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bob found a pair!'), findsOneWidget);

      await tester.pump(RivalEventBanner.visibleFor);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bob found a pair!'), findsNothing);

      await pump(
        tester,
        const DuelProgress(
          round: 0,
          score: 485,
          seq: 3,
          event: DuelEvent.miss,
          cards: [1, 2],
          matched: [0, 5],
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bob missed a pair'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('el espejo se reduce y se amplía al tocarlo', (tester) async {
      await pump(tester, const DuelProgress(round: 0, score: 120, seq: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('120 pts'), findsOneWidget);

      await tester.tap(find.byType(OpponentMirror));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('120 pts'), findsNothing, reason: 'compacto');

      await tester.tap(find.byType(OpponentMirror));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('120 pts'), findsOneWidget);
    });
  });
}
