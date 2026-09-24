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
import 'package:memory_companion/features/minigames/modules/digits/controller/digits_controller.dart';
import 'package:memory_companion/features/minigames/modules/digits/digits_screen.dart';
import 'package:memory_companion/features/minigames/modules/digits/model/digits_state.dart';
import 'package:memory_companion/features/minigames/modules/words/words_screen.dart';

class _RecordingReporter implements MinigameResultReporter {
  final reports = <MinigameResult>[];

  @override
  Future<void> report(BaseMinigame game, MinigameResult result) async {
    reports.add(result);
  }
}

void main() {
  setUpAll(() async {
    // flutter_localization lee el idioma guardado de shared_preferences, que
    // no tiene plugin en los tests: se responde con preferencias vacías.
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

  late _RecordingReporter reporter;

  Future<void> pumpGame(WidgetTester tester, Widget screen) async {
    reporter = _RecordingReporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          minigameRandomProvider.overrideWithValue(Random(1)),
          minigameResultReporterProvider.overrideWithValue(reporter),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FlutterLocalization.instance.supportedLocales,
          localizationsDelegates:
              FlutterLocalization.instance.localizationsDelegates,
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Dígitos: se juega un número con el teclado', (tester) async {
    await pumpGame(tester, const DigitsScreen());

    await tester.tap(find.text('In order'));
    await tester.pump();
    expect(find.text('Memorize'), findsOneWidget);

    await tester.pump(digitsShowDuration(3));
    expect(find.text('Type the number'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DigitsScreen)),
    );
    final answer = container.read(digitsControllerProvider).expectedAnswer;
    for (final digit in answer.split('')) {
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text(digit),
        ),
      );
      await tester.pump();
    }
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();
    expect(find.text('Correct!'), findsOneWidget);

    await tester.pump(digitsFeedbackDuration);
    expect(find.text('4 digits'), findsOneWidget);
    // Sale sin dejar temporizadores vivos.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Palabras: se estudia, se responde y se ve el resultado', (
    tester,
  ) async {
    await pumpGame(tester, const WordsScreen());

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Memorize these words'), findsOneWidget);

    await tester.tap(find.text("I've got them"));
    await tester.pump();
    expect(find.text('Was it on the list?'), findsOneWidget);
    expect(find.text('1 of 8'), findsOneWidget);

    for (var i = 0; i < 8; i++) {
      await tester.ensureVisible(find.text('Yes, it was'));
      await tester.tap(find.text('Yes, it was'));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Nice workout!'), findsOneWidget);
    expect(find.text('4 of 8 right'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    expect(reporter.reports.single.won, isFalse);
  });
}
