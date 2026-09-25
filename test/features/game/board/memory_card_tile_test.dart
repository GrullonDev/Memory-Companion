import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/game/board/model/card_face.dart';
import 'package:memory_companion/features/game/board/model/memory_card.dart';
import 'package:memory_companion/features/game/board/widget/memory_card_tile.dart';

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

  Future<void> pump(
    WidgetTester tester,
    MemoryCard card, {
    ProfileTokens tokens = ProfileTokens.vibrant,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FlutterLocalization.instance.supportedLocales,
        localizationsDelegates:
            FlutterLocalization.instance.localizationsDelegates,
        theme: ThemeData(extensions: [tokens]),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: MemoryCardTile(card: card, onTap: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const faceDown = MemoryCard(id: 0, pairId: 'a', face: SymbolFace('🍓'));

  for (final tokens in [ProfileTokens.vibrant, ProfileTokens.accessible]) {
    final profile = tokens.isAccessible ? 'accessible' : 'vibrant';

    testWidgets('$profile: both faces fill the whole cell', (tester) async {
      await pump(tester, faceDown, tokens: tokens);
      expect(
        tester.getSize(find.byKey(const ValueKey('down'))),
        const Size(100, 100),
      );

      await pump(tester, faceDown.copyWith(isFaceUp: true), tokens: tokens);
      expect(
        tester.getSize(find.byKey(const ValueKey('up'))),
        const Size(100, 100),
      );

      await pump(tester, faceDown.copyWith(isMatched: true), tokens: tokens);
      expect(
        tester.getSize(find.byKey(const ValueKey('up'))),
        const Size(100, 100),
      );
    });
  }
}
