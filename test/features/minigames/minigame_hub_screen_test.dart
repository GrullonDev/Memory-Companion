import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';
import 'package:memory_companion/features/minigames/hub/minigame_hub_screen.dart';
import 'package:memory_companion/features/minigames/minigame_registry.dart';
import 'package:memory_companion/features/minigames/modules/memory/memory_game_module.dart';

class _SequenceGame extends BaseMinigame {
  const _SequenceGame();

  @override
  String get id => 'sequence';
  @override
  String get titleKey => AppLocale.minigameMemoryTitle;
  @override
  String get descriptionKey => AppLocale.minigameMemoryDescription;
  @override
  IconData get icon => Icons.pin_rounded;
  @override
  MinigamePalette get palette => MinigamePalette.sky;
  @override
  Widget buildGameScreen() => const SizedBox.shrink();
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

  testWidgets('muestra cada juego registrado y lo abre al tocarlo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          minigamesProvider.overrideWithValue(const [
            MemoryGameModule(),
            _SequenceGame(),
          ]),
        ],
        child: MaterialApp(
          supportedLocales: FlutterLocalization.instance.supportedLocales,
          localizationsDelegates:
              FlutterLocalization.instance.localizationsDelegates,
          home: const MinigameHubScreen(),
          // Solo se navega al juego de prueba, que no está en el registro.
          onGenerateRoute: (settings) => MaterialPageRoute(
            settings: settings,
            builder: (_) => Text('opened ${settings.name}'),
          ),
        ),
      ),
    );
    // Los textos llegan cuando el delegado de traducciones termina de cargar.
    await tester.pumpAndSettle();

    expect(find.text('Brain games'), findsOneWidget);
    expect(find.text('Memory'), findsNWidgets(2));
    expect(find.byIcon(Icons.pin_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pin_rounded));
    await tester.pumpAndSettle();
    expect(find.text('opened /games/sequence'), findsOneWidget);
  });
}
