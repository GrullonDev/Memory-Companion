import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';
import 'package:memory_companion/features/level_map/widget/level_path.dart';

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

  Future<List<int>> pump(
    WidgetTester tester, {
    required int currentLevel,
    ProfileTokens tokens = ProfileTokens.vibrant,
  }) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FlutterLocalization.instance.supportedLocales,
        localizationsDelegates:
            FlutterLocalization.instance.localizationsDelegates,
        theme: ThemeData(extensions: [tokens]),
        home: Scaffold(
          body: ListView(
            children: [
              LevelPath(
                levels: LevelNode.pathAround(currentLevel),
                onSelectLevel: (node) => taps.add(node.number),
              ),
            ],
          ),
        ),
      ),
    );
    // The localization delegate loads asynchronously; nothing below
    // `Localizations` is built until it has.
    await tester.pump();
    return taps;
  }

  testWidgets('cada nodo muestra su estado: check, actual o candado', (
    tester,
  ) async {
    await pump(tester, currentLevel: 3);

    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(3));
    expect(find.bySemanticsLabel('Level 2, completed'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Level 3, current level, tap to play'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Level 4, locked'), findsOneWidget);
  });

  testWidgets('un nodo bloqueado no responde; el actual sí', (tester) async {
    final taps = await pump(tester, currentLevel: 3);

    await tester.tap(find.text('Level 4'), warnIfMissed: false);
    await tester.tap(find.text('Level 3'));
    expect(taps, [3]);
  });

  testWidgets('perfil accesible con texto grande: sin desbordes', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, currentLevel: 1, tokens: ProfileTokens.accessible);

    expect(tester.takeException(), isNull);
    expect(find.text('Level 1'), findsOneWidget);
  });
}
