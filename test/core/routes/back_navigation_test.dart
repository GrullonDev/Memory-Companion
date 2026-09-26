import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/routes/route_switch.dart';
import 'package:memory_companion/core/routes/tab_root_scope.dart';

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

  test('el arranque apila solo la ruta pedida, sin un "/" fantasma', () {
    final routes = RouteSwitch.onGenerateInitialRoutes(RoutePaths.splash);
    expect(routes, hasLength(1));
    expect(routes.single.settings.name, RoutePaths.splash);
  });

  /// Records `SystemNavigator.pop`, which closes the app.
  List<String> recordExits(WidgetTester tester) {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call.method);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return calls;
  }

  Widget tab(String name) => TabRootScope(
    isHome: name == RoutePaths.home,
    child: Scaffold(body: Text('tab:$name')),
  );

  Future<void> pump(WidgetTester tester, String initial) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FlutterLocalization.instance.supportedLocales,
        localizationsDelegates:
            FlutterLocalization.instance.localizationsDelegates,
        initialRoute: initial,
        onGenerateInitialRoutes: (name) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: name),
            builder: (_) => tab(name),
          ),
        ],
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => tab(settings.name!),
        ),
      ),
    );
    // The localization delegates load asynchronously.
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('en Home, atrás pide confirmar y el segundo sale de la app', (
    tester,
  ) async {
    final exits = recordExits(tester);
    await pump(tester, RoutePaths.home);

    await back(tester);
    expect(find.text('tab:home'), findsNothing);
    expect(find.text('tab:${RoutePaths.home}'), findsOneWidget);
    expect(find.text('Press back again to exit'), findsOneWidget);
    expect(exits, isNot(contains('SystemNavigator.pop')));

    await back(tester);
    expect(exits, contains('SystemNavigator.pop'));
    expect(find.text("We couldn't find this screen."), findsNothing);
  });

  testWidgets('pasado el plazo, hay que volver a confirmar', (tester) async {
    final exits = recordExits(tester);
    await pump(tester, RoutePaths.home);

    await back(tester);
    await tester.pump(TabRootScope.exitWindow + const Duration(seconds: 1));
    await back(tester);
    expect(exits, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('en otra pestaña, atrás lleva a Home', (tester) async {
    final exits = recordExits(tester);
    await pump(tester, RoutePaths.versus);

    await back(tester);
    expect(find.text('tab:${RoutePaths.home}'), findsOneWidget);
    expect(find.text('tab:${RoutePaths.versus}'), findsNothing);
    expect(exits, isNot(contains('SystemNavigator.pop')));
  });

  testWidgets('una pestaña abierta encima de Home vuelve a Home', (
    tester,
  ) async {
    await pump(tester, RoutePaths.home);
    final context = tester.element(find.text('tab:${RoutePaths.home}'));
    Navigator.of(context).pushNamed(RoutePaths.friends);
    await tester.pumpAndSettle();

    await back(tester);
    expect(find.text('tab:${RoutePaths.home}'), findsOneWidget);
    expect(find.text('Press back again to exit'), findsNothing);
  });

  testWidgets('cambiar de pestaña no apila pantallas', (tester) async {
    await pump(tester, RoutePaths.home);
    for (final index in [1, 2, 0, 1]) {
      final context = tester.element(find.byType(Scaffold).last);
      RoutePaths.navigateToTab(context, index);
      await tester.pumpAndSettle();
    }
    final context = tester.element(find.text('tab:${RoutePaths.versus}'));
    expect(Navigator.of(context).canPop(), isFalse);
  });

  testWidgets('una ruta desconocida ofrece volver al menú', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: FlutterLocalization.instance.supportedLocales,
        localizationsDelegates:
            FlutterLocalization.instance.localizationsDelegates,
        initialRoute: '/nope',
        onGenerateInitialRoutes: (name) => [
          RouteSwitch.onGenerateRoute(RouteSettings(name: name)),
        ],
        onGenerateRoute: (settings) => settings.name == RoutePaths.home
            ? MaterialPageRoute<void>(builder: (_) => tab(RoutePaths.home))
            : RouteSwitch.onGenerateRoute(settings),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("We couldn't find this screen."), findsOneWidget);
    await tester.tap(find.text('Back to Menu'));
    await tester.pumpAndSettle();
    expect(find.text('tab:${RoutePaths.home}'), findsOneWidget);
  });
}
