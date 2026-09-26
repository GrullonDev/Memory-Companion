import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/level_map/controller/map_navigator_controller.dart';
import 'package:memory_companion/features/level_map/level_map_screen.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';
import 'package:memory_companion/features/level_map/widget/map_navigator_button.dart';

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
      initLanguageCode: 'en',
    );
  });

  group('MapProgress', () {
    test('cuenta los niveles superados y el próximo premio', () {
      const progress = MapProgress(currentLevel: 3);
      expect(progress.levelsCleared, 2);
      expect(progress.nextReward.level, 5);
      expect(progress.levelsToReward, 3);
      expect(progress.rewardWithinReach, isFalse);
    });

    test('a un tablero del premio, lo avisa', () {
      const progress = MapProgress(currentLevel: 5);
      expect(progress.levelsToReward, 1);
      expect(progress.rewardWithinReach, isTrue);
    });

    test('el nivel 10 es un cofre', () {
      expect(const MapProgress(currentLevel: 8).nextReward.isChest, isTrue);
    });
  });

  group('LevelMapScreen', () {
    Future<({List<int> played, List<bool> hintSeen})> pump(
      WidgetTester tester, {
      int currentLevel = 3,
      bool showHint = false,
    }) async {
      final played = <int>[];
      final hintSeen = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FlutterLocalization.instance.supportedLocales,
          localizationsDelegates:
              FlutterLocalization.instance.localizationsDelegates,
          theme: ThemeData(extensions: const [ProfileTokens.vibrant]),
          home: Scaffold(
            body: LevelMapScreen(
              regionName: 'Forest of Riddles',
              levels: LevelNode.pathAround(currentLevel),
              progress: MapProgress(currentLevel: currentLevel),
              showNavigatorHint: showHint,
              onNavigatorHintSeen: () => hintSeen.add(true),
              onSelectLevel: (node) => played.add(node.number),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      return (played: played, hintSeen: hintSeen);
    }

    testWidgets('la primera visita explica el botón del mapa', (tester) async {
      final result = await pump(tester, showHint: true);
      expect(
        find.text('Your map: progress, rewards and a shortcut to your level.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Got it'));
      expect(result.hintSeen, [true]);
    });

    testWidgets('sin pista pendiente no hay burbuja', (tester) async {
      await pump(tester);
      expect(find.byType(MapNavigatorHint), findsNothing);
    });

    testWidgets('el navegador resume el progreso y juega el nivel', (
      tester,
    ) async {
      final result = await pump(tester);
      await tester.tap(find.byType(MapNavigatorButton));
      await tester.pumpAndSettle();

      expect(
        find.text('You are on level 3 · 2 levels cleared'),
        findsOneWidget,
      );
      expect(find.text('100-coin gift at level 5'), findsOneWidget);
      expect(find.text('3 levels to go'), findsOneWidget);

      await tester.tap(find.text('Play level 3'));
      await tester.pumpAndSettle();
      expect(result.played, [3]);
    });

    testWidgets('"Ir a mi nivel" cierra el navegador sin errores', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.byType(MapNavigatorButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to my level').last);
      await tester.pumpAndSettle();
      expect(find.text('Play level 3'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a un tablero del premio, el botón lleva la insignia', (
      tester,
    ) async {
      await pump(tester, currentLevel: 5);
      expect(
        find.descendant(
          of: find.byType(MapNavigatorButton),
          matching: find.byIcon(Icons.card_giftcard_rounded),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(MapNavigatorButton));
      // Not pumpAndSettle: the badge breathes for as long as it shows.
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Win one more board and it is yours!'), findsOneWidget);
    });
  });
}
