import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/connectivity/widget/connectivity_banner.dart';
import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/routes/route_switch.dart';
import 'package:memory_companion/core/theme/app_theme.dart';

const List<String> _supportedLanguageCodes = ['es', 'en'];

/// Upper bound applied to the OS font-size setting.
///
/// Players who enlarge system text get that enlargement — up to 135%, which
/// covers the common "Large"/"Larger" accessibility steps. Past that point a
/// game HUD stops fitting on a phone at all, so we cap rather than let the
/// board and the score overflow. Layouts are built to survive the full range.
const double _maxTextScale = 1.35;

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      initialRoute: RoutePaths.splash,
      onGenerateRoute: RouteSwitch.onGenerateRoute,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxTextScale,
        child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
