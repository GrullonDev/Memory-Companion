import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/game/board/category/game_categories.dart';
import 'package:memory_companion/features/ladder/game_ladder.dart';
import 'package:memory_companion/features/minigames/modules/crossword/crossword_game_module.dart';
import 'package:memory_companion/features/home/model/home_summary.dart';
import 'package:memory_companion/features/home/widget/level_progress_card.dart';

void main() {
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
      initLanguageCode: 'es',
    );
  });

  final summary = HomeSummary(
    playerName: 'Jugador',
    totalXp: 900,
    streakDays: 2,
    isLoading: false,
    ladders: [
      GameLadder.board(GameCategories.classic, level: 7),
      GameLadder.board(GameCategories.numeric, level: 5),
      GameLadder.board(GameCategories.association, level: 1),
      GameLadder.minigame(const CrosswordGameModule(), level: 3),
    ],
  );

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: FlutterLocalization.instance.supportedLocales,
        localizationsDelegates:
            FlutterLocalization.instance.localizationsDelegates,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(320, 800),
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: LevelProgressCard(summary: summary),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('muestra el nivel del mapa y el próximo premio', (tester) async {
    await pump(tester);

    expect(find.text('Nivel 7'), findsOneWidget);
    expect(
      find.text('Completa 4 niveles más y gana un cofre de 400 monedas'),
      findsOneWidget,
    );
    // Cada juego con su propia escalera.
    expect(find.text('Clásico · Nivel 7'), findsOneWidget);
    expect(find.textContaining('· Nivel 5'), findsOneWidget);
    expect(find.textContaining('· Nivel 1'), findsOneWidget);
    // Los minijuegos también suben su propia escalera.
    expect(find.textContaining('· Nivel 3'), findsOneWidget);
  });

  testWidgets('no desborda en pantalla estrecha con texto grande', (
    tester,
  ) async {
    await pump(tester, textScale: 1.35);
    expect(tester.takeException(), isNull);
  });
}
