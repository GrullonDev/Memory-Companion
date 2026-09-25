import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/friends/controller/friends_controller.dart';
import 'package:memory_companion/features/friends/model/friend.dart';
import 'package:memory_companion/features/friends/model/friend_code.dart';
import 'package:memory_companion/features/friends/model/public_player.dart';
import 'package:memory_companion/features/game_context/controller/game_context_providers.dart';
import 'package:memory_companion/features/settings/controller/display_preferences_controller.dart';

enum NearbySearchStatus {
  idle,
  searching,
  done,

  /// The player did not grant the Bluetooth permissions.
  permissionDenied,

  /// Bluetooth is off or missing on this device.
  unavailable,
}

/// Someone heard over Bluetooth during a search.
class NearbyFound {
  const NearbyFound({required this.code, this.player, this.friend});

  final String code;

  /// Their public profile, when the code could be looked up.
  final PublicPlayer? player;

  /// Set when they are already a friend or a request is pending.
  final Friend? friend;

  String get name {
    final known = friend?.name ?? player?.displayName ?? '';
    return known.isEmpty ? code : known;
  }
}

class NearbySearchState {
  const NearbySearchState({
    this.status = NearbySearchStatus.idle,
    this.found = const [],
  });

  final NearbySearchStatus status;
  final List<NearbyFound> found;
}

/// "Find players nearby" on the Friends screen.
///
/// Both phones have to be searching (or have "nearby players" on) at the
/// same time: while it searches, this one also advertises itself so the
/// other finds it back.
class NearbySearchController extends Notifier<NearbySearchState> {
  static const Duration scanDuration = Duration(seconds: 12);

  @override
  NearbySearchState build() => const NearbySearchState();

  Future<void> search() async {
    if (state.status == NearbySearchStatus.searching) return;
    final radio = ref.read(nearbyRadioProvider);
    final uid = await ref.read(socialUidProvider.future);
    if (uid == null) return;
    final own = FriendCode.fromUid(uid);

    if (!await radio.requestPermission()) {
      state = const NearbySearchState(
        status: NearbySearchStatus.permissionDenied,
      );
      return;
    }
    state = NearbySearchState(
      status: NearbySearchStatus.searching,
      found: state.found,
    );

    await radio.startAdvertising(own);
    final Set<String>? heard;
    try {
      heard = await radio.scan(scanDuration);
    } finally {
      // The beacon keeps advertising on its own when the switch is on.
      if (!ref.read(displayPreferencesProvider).contextNearby) {
        await radio.stopAdvertising();
      }
    }
    if (!ref.mounted) return;
    if (heard == null) {
      state = const NearbySearchState(status: NearbySearchStatus.unavailable);
      return;
    }

    final codes = heard.difference({own}).toList()..sort();
    final friends = ref.read(friendsControllerProvider).value;
    final everyone = [
      ...?friends?.friends,
      ...?friends?.incoming,
      ...?friends?.outgoing,
    ];
    final repository = ref.read(socialRepositoryProvider);
    final found = await Future.wait([
      for (final code in codes)
        () async {
          Friend? friend;
          for (final f in everyone) {
            if (FriendCode.fromUid(f.uid) == code) friend = f;
          }
          PublicPlayer? player;
          if (friend == null) {
            try {
              player = await repository.findByCode(code);
            } on Exception {
              player = null;
            }
          }
          return NearbyFound(code: code, player: player, friend: friend);
        }(),
    ]);
    if (!ref.mounted) return;
    state = NearbySearchState(status: NearbySearchStatus.done, found: found);
  }
}

final nearbySearchControllerProvider =
    NotifierProvider.autoDispose<NearbySearchController, NearbySearchState>(
      NearbySearchController.new,
    );
