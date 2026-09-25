import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/core/minigame_random.dart';
import 'package:memory_companion/features/minigames/core/minigame_result.dart';
import 'package:memory_companion/features/minigames/core/minigame_result_reporter.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_screen.dart';
import 'package:memory_companion/features/minigames/modules/crossword/widget/letter_wheel.dart';
import 'package:memory_companion/features/statistics/controller/statistics_controller.dart';
import 'package:memory_companion/features/statistics/repository/stats_repository.dart';

/// Un jugador sin partidas: el crucigrama empieza en el nivel 1.
class _NewPlayerStats implements StatsRepository {
  @override
  Future<int> countWins(String categoryId) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingReporter implements MinigameResultReporter {
  final reports = <MinigameResult>[];

  @override
  Future<void> report(BaseMinigame game, MinigameResult result) async {
    reports.add(result);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (_) async => <String, Object>{},
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

  Finder letter(String value) =>
      find.descendant(of: find.byType(LetterWheel), matching: find.text(value));

  testWidgets('se juega deslizando y tocando en un teléfono de 360 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final reporter = _RecordingReporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsRepositoryProvider.overrideWithValue(_NewPlayerStats()),
          minigameResultReporterProvider.overrideWithValue(reporter),
          minigameRandomProvider.overrideWithValue(Random(4)),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FlutterLocalization.instance.supportedLocales,
          localizationsDelegates:
              FlutterLocalization.instance.localizationsDelegates,
          home: const CrosswordScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Nivel 1 en inglés: CAT y ACT.
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('0 of 2 words'), findsOneWidget);

    // Deslizar C → A → T y soltar.
    final gesture = await tester.startGesture(tester.getCenter(letter('C')));
    await tester.pump();
    for (final next in ['A', 'T']) {
      await gesture.moveTo(tester.getCenter(letter(next)));
      await tester.pump();
    }
    expect(find.text('CAT'), findsOneWidget, reason: 'la palabra en curso');
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('CAT!'), findsOneWidget);
    expect(find.text('1 of 2 words'), findsOneWidget);

    // Tocar A, C, T y enviar.
    for (final next in ['A', 'C', 'T']) {
      await tester.tap(letter(next));
      await tester.pump();
    }
    await tester.tap(find.text('Enter'));
    await tester.pumpAndSettle();

    expect(find.text('Level cleared'), findsOneWidget);
    expect(find.text('Puzzle solved without hints!'), findsOneWidget);
    expect(reporter.reports.single.won, isTrue);

    await tester.tap(find.text('Next Level'));
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'un deslizamiento vertical, paso a paso como un dedo real, deletrea '
    'en vez de desplazar la pantalla',
    (tester) async {
      // Short phone: the screen scrolls, so its list competes for drags.
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statsRepositoryProvider.overrideWithValue(_NewPlayerStats()),
            minigameResultReporterProvider.overrideWithValue(
              _RecordingReporter(),
            ),
            minigameRandomProvider.overrideWithValue(Random(4)),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: FlutterLocalization.instance.supportedLocales,
            localizationsDelegates:
                FlutterLocalization.instance.localizationsDelegates,
            home: const CrosswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bring the whole wheel on screen first, as a player would.
      await tester.ensureVisible(find.byType(LetterWheel));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final offsetBefore = scrollable.position.pixels;

      // From the top letter straight down to one of the two below it: a
      // mostly vertical stroke, which the list used to take as a scroll.
      final letters = ['C', 'A', 'T']
        ..sort(
          (a, b) => tester
              .getCenter(letter(a))
              .dy
              .compareTo(tester.getCenter(letter(b)).dy),
        );
      final top = letters.first;
      final below = letters[1];
      final from = tester.getCenter(letter(top));
      final to = tester.getCenter(letter(below));

      final gesture = await tester.startGesture(from);
      await tester.pump();
      const steps = 40;
      for (var i = 1; i <= steps; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
        await tester.pump();
      }

      expect(
        find.text('$top$below'),
        findsOneWidget,
        reason: 'the stroke spells, letter by letter',
      );
      expect(scrollable.position.pixels, offsetBefore);
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );
}
