import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/connectivity/widget/connectivity_banner.dart';
import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/routes/route_switch.dart';

const List<String> _supportedLanguageCodes = ['es', 'en'];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  void initState() {
    super.initState();
    _localization.onTranslatedLanguage = (_) => setState(() {});
    final deviceLanguageCode = _localization.currentLocale?.languageCode;
    final initLanguageCode =
        _supportedLanguageCodes.contains(deviceLanguageCode)
        ? deviceLanguageCode!
        : 'es';
    _localization.init(
      initLanguageCode: initLanguageCode,
      mapLocales: const [
        MapLocale('es', AppLocale.es, countryCode: 'ES'),
        MapLocale('en', AppLocale.en, countryCode: 'US'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Arcade',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      initialRoute: RoutePaths.splash,
      onGenerateRoute: RouteSwitch.onGenerateRoute,
      builder: (context, child) =>
          ConnectivityBanner(child: child ?? const SizedBox.shrink()),
    );
  }
}
