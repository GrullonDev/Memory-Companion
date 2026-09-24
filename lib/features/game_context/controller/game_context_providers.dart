import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/game_context/model/place.dart';
import 'package:memory_companion/features/game_context/repository/place_repository.dart';
import 'package:memory_companion/features/game_context/service/game_context_capturer.dart';
import 'package:memory_companion/features/game_context/service/location_source.dart';
import 'package:memory_companion/features/game_context/service/nearby_radio.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';

final locationSourceProvider = Provider<LocationSource>(
  (_) => const GeolocatorLocationSource(),
);

/// One radio for the whole app: it remembers what it is advertising.
final nearbyRadioProvider = Provider<NearbyRadio>((_) => BleNearbyRadio());

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepository(database: ref.watch(appDatabaseProvider)),
);

/// Every known place, oldest first.
final placesProvider = StreamProvider.autoDispose<List<Place>>(
  (ref) => ref.watch(placeRepositoryProvider).watchAll(),
);

/// The player's own friend code, or null without an account.
Future<String?> _ownCode(Ref ref) async {
  final uid = await ref.read(socialUidProvider.future);
  return uid == null ? null : FriendCode.fromUid(uid);
}

final gameContextCapturerProvider = Provider<GameContextCapturer>((ref) {
  return GameContextCapturer(
    preferences: () => ref.read(displaySettingsRepositoryProvider).read(),
    location: ref.watch(locationSourceProvider),
    places: ref.watch(placeRepositoryProvider),
    radio: ref.watch(nearbyRadioProvider),
    ownCode: () => _ownCode(ref),
    friendNamesByCode: () async {
      final state = await ref.read(friendsControllerProvider.future);
      return {
        for (final friend in state.friends)
          if (friend.name.isNotEmpty)
            FriendCode.fromUid(friend.uid): friend.name,
      };
    },
  );
});

/// Whether the app is in front of the player.
class AppForegroundController extends Notifier<bool> {
  @override
  bool build() {
    final listener = AppLifecycleListener(
      onStateChange: (lifecycle) =>
          state = lifecycle == AppLifecycleState.resumed,
    );
    ref.onDispose(listener.dispose);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }
}

final appForegroundProvider = NotifierProvider<AppForegroundController, bool>(
  AppForegroundController.new,
);

/// Keeps this player discoverable while "nearby players" is on, they have
/// an account and the app is in front. Watched once from the app root.
///
/// Advertising is what lets other phones list this player and store them
/// in their game context; it broadcasts only the friend code, which is
/// already what the player shares to be added.
final nearbyBeaconProvider = Provider<void>((ref) {
  final enabled = ref.watch(
    displayPreferencesProvider.select((p) => p.contextNearby),
  );
  // Nothing else is watched while it is off, so an install without the
  // switch never touches Firebase or Bluetooth from here.
  if (!enabled) return;
  if (!ref.watch(appForegroundProvider)) return;
  final uid = ref.watch(socialUidProvider).value;
  if (uid == null) return;

  final radio = ref.watch(nearbyRadioProvider);
  radio.startAdvertising(FriendCode.fromUid(uid));
  ref.onDispose(radio.stopAdvertising);
});
