import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/connectivity/widget/connectivity_banner.dart';
import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/routes/route_switch.dart';
import 'package:memory_companion/core/theme/app_theme.dart';
import 'package:memory_companion/core/theme/profile_tokens.dart';
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';

const List<String> _supportedLanguageCodes = ['es', 'en'];

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
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
    // Read from the local database. Until the first read lands (a few ms,
    // behind the splash) this is the vibrant default.
    final profile = ref.watch(
      displayPreferencesProvider.select((p) => p.visualProfile),
    );
    final tokens = ProfileTokens.forProfile(profile);
    // Advertises the player over Bluetooth while "nearby players" is on.
    ref.watch(nearbyBeaconProvider);

    return MaterialApp(
      title: 'Memory Arcade',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(profile: profile),
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      initialRoute: RoutePaths.splash,
      onGenerateRoute: RouteSwitch.onGenerateRoute,
      // Players who enlarge system text get that enlargement — up to 135%,
      // which covers the common "Large"/"Larger" accessibility steps. Past
      // that a game HUD stops fitting on a phone, so we cap rather than let
      // the board overflow. The accessible profile raises the *floor*, so
      // text is large even on a phone left at default settings.
      builder: (context, child) {
        final content = MediaQuery.withClampedTextScaling(
          minScaleFactor: tokens.minTextScale,
          maxScaleFactor: tokens.maxTextScale,
          child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
        );
        if (!tokens.reduceMotion) return content;
        // Every widget that honours the OS "reduce motion" setting calms down
        // too, without having to know the profile exists.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: content,
        );
      },
    );
  }
}
