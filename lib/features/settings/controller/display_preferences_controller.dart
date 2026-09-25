import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/core/theme/visual_profile.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';
import 'package:memory_companion/features/settings/repository/display_settings_repository.dart';

final displaySettingsRepositoryProvider = Provider<DisplaySettingsRepository>(
  (ref) => DisplaySettingsRepository(database: ref.watch(appDatabaseProvider)),
);

/// The single source of the active visual profile for the whole app.
///
/// Backed by a Drift stream, so a write from any screen reaches `MyApp`
/// — and therefore the theme — without anyone calling `setState`.
class DisplayPreferencesController extends StreamNotifier<DisplayPreferences> {
  @override
  Stream<DisplayPreferences> build() {
    // The theme listens to this for the app's whole lifetime; it must never
    // be torn down and re-read between screens.
    ref.keepAlive();
    return ref.watch(displaySettingsRepositoryProvider).watch();
  }

  Future<void> setVisualProfile(VisualProfile profile) {
    return ref
        .read(displaySettingsRepositoryProvider)
        .setVisualProfile(profile);
  }

  Future<void> setTimedMatches(bool enabled) {
    return ref.read(displaySettingsRepositoryProvider).setTimedMatches(enabled);
  }

  Future<void> setContextLocation(bool enabled) {
    return ref
        .read(displaySettingsRepositoryProvider)
        .setContextLocation(enabled);
  }

  Future<void> setContextNearby(bool enabled) {
    return ref
        .read(displaySettingsRepositoryProvider)
        .setContextNearby(enabled);
  }
}

final displayPreferencesControllerProvider =
    StreamNotifierProvider<DisplayPreferencesController, DisplayPreferences>(
      DisplayPreferencesController.new,
    );

/// Synchronous view of the preferences for code that cannot wait: the theme
/// on the first frame, and the board when a match starts. Falls back to
/// [DisplayPreferences.defaults] until the first database read lands.
final displayPreferencesProvider = Provider<DisplayPreferences>((ref) {
  return ref.watch(displayPreferencesControllerProvider).value ??
      DisplayPreferences.defaults;
});
