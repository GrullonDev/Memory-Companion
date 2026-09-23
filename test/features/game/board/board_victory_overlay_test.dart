import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/game/board/widget/board_victory_overlay.dart';

void main() {
  setUpAll(() async {
    // flutter_localization keeps the chosen language in shared_preferences;
    // the test has no platform side, so it starts from an empty store.
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

  Future<List<String>> pump(
    WidgetTester tester, {
    required bool won,
    int stars = 2,
    ProfileTokens tokens = ProfileTokens.vibrant,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FlutterLocalization.instance.supportedLocales,
        localizationsDelegates:
            FlutterLocalization.instance.localizationsDelegates,
        theme: ThemeData(extensions: [tokens]),
        home: MediaQuery(
          // As the app does for the accessible profile; keeps confetti and
          // the star pop from running forever in the test.
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: BoardVictoryOverlay(
              won: won,
              stars: stars,
              score: 1250,
              moves: 9,
              elapsedSeconds: 75,
              coinsEarned: won ? 24 : 0,
              xpEarned: won ? 80 : 10,
              onNextLevel: () => taps.add('next'),
              onPlayAgain: () => taps.add('again'),
              onViewStats: () => taps.add('stats'),
              onExit: () => taps.add('exit'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return taps;
  }

  testWidgets('una victoria ofrece Next Level como acción principal', (
    tester,
  ) async {
    final taps = await pump(tester, won: true);

    expect(find.text('VICTORY!'), findsOneWidget);
    expect(find.bySemanticsLabel('2 of 3 stars'), findsOneWidget);
    expect(find.text('+24'), findsOneWidget);
    expect(find.text('Play again'), findsNothing);

    await tester.tap(find.text('Next Level'));
    await tester.ensureVisible(find.text('View stats'));
    await tester.tap(find.text('View stats'));
    await tester.ensureVisible(find.text('Back to Menu'));
    await tester.tap(find.text('Back to Menu'));
    expect(taps, ['next', 'stats', 'exit']);
  });

  testWidgets('sin tiempo: sin estrellas, y la acción es reintentar', (
    tester,
  ) async {
    final taps = await pump(tester, won: false, stars: 0);

    expect(find.text("TIME'S UP!"), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('of 3 stars')), findsNothing);
    expect(find.text('Next Level'), findsNothing);

    await tester.tap(find.text('Play again'));
    expect(taps, ['again']);
  });

  testWidgets('el perfil accesible usa botones de al menos 72px', (
    tester,
  ) async {
    await pump(tester, won: true, tokens: ProfileTokens.accessible);

    final button = find.ancestor(
      of: find.text('Next Level'),
      matching: find.byType(Container),
    );
    expect(
      tester.getSize(button.first).height,
      greaterThanOrEqualTo(ProfileTokens.accessible.buttonMinHeight),
    );
    expect(tester.takeException(), isNull);
  });
}
