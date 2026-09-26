import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/ladder/game_ladder.dart';
import 'package:memory_companion/features/ladder/ladder_controller.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/minigames/core/widget/minigame_result_view.dart';
import 'package:memory_companion/features/minigames/modules/words/words_game_module.dart';

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

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: FlutterLocalization.instance.supportedLocales,
          localizationsDelegates:
              FlutterLocalization.instance.localizationsDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MinigameResultView(
                game: const WordsGameModule(),
                won: true,
                headline: '8 of 8',
                caption: 'List of 4 words',
                message: 'Great',
                primaryLabel: 'Play again',
                onPrimary: () {},
              ),
            ),
          ),
        ),
      ),
    );
    return container;
  }

  testWidgets('anuncia el nivel completado y el premio de la escalera', (
    tester,
  ) async {
    final container = await pump(tester);
    expect(find.textContaining('complete'), findsNothing);

    // Llega un instante después, cuando el resultado ya está guardado.
    container
        .read(ladderRoundNoticesProvider.notifier)
        .set(
          GameLadder.minigameId(const WordsGameModule()),
          LadderRoundNotice(
            completedLevel: 5,
            rewards: [LevelRewards.forCompletedLevel(5)!],
          ),
        );
    await tester.pump();

    expect(find.text('Level 5 complete'), findsOneWidget);
    expect(find.text('Level gift!'), findsOneWidget);
    expect(find.text('+100 coins'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
