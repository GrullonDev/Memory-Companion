import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:memory_companion/features/game_context/model/nearby_player.dart';
import 'package:memory_companion/features/game_context/repository/place_repository.dart';
import 'package:memory_companion/features/game_context/service/location_source.dart';
import 'package:memory_companion/features/game_context/service/nearby_radio.dart';
import 'package:memory_companion/features/settings/model/display_preferences.dart';

/// Where and with whom a game was played.
class GameContext {
  const GameContext({this.placeId, this.nearby});

  static const GameContext none = GameContext();

  final int? placeId;
  final List<NearbyPlayer>? nearby;
}

/// Reads the context of a game that just ended, as far as the player
/// allowed it.
///
/// Each half runs only if its switch is on, and both run at once. Neither
/// can fail the game: any error, missing permission or slow radio leaves
/// that half empty. Nothing read here leaves the device.
class GameContextCapturer {
  GameContextCapturer({
    required Future<DisplayPreferences> Function() preferences,
    required LocationSource location,
    required PlaceRepository places,
    required NearbyRadio radio,
    required Future<String?> Function() ownCode,
    required Future<Map<String, String>> Function() friendNamesByCode,
    this.scanDuration = const Duration(seconds: 4),
  }) : _preferences = preferences,
       _location = location,
       _places = places,
       _radio = radio,
       _ownCode = ownCode,
       _friendNames = friendNamesByCode;

  final Future<DisplayPreferences> Function() _preferences;
  final LocationSource _location;
  final PlaceRepository _places;
  final NearbyRadio _radio;
  final Future<String?> Function() _ownCode;
  final Future<Map<String, String>> Function() _friendNames;

  /// How long to listen for nearby players. Short: the result screen is
  /// already showing, this only delays the history row.
  final Duration scanDuration;

  Future<GameContext> capture() async {
    final DisplayPreferences preferences;
    try {
      preferences = await _preferences();
    } catch (_) {
      return GameContext.none;
    }
    if (!preferences.contextLocation && !preferences.contextNearby) {
      return GameContext.none;
    }
    final (placeId, nearby) = await (
      preferences.contextLocation ? _place() : Future<int?>.value(),
      preferences.contextNearby
          ? _nearby()
          : Future<List<NearbyPlayer>?>.value(),
    ).wait;
    return GameContext(placeId: placeId, nearby: nearby);
  }

  Future<int?> _place() async {
    try {
      final here = await _location.current();
      if (here == null) return null;
      return await _places.resolve(here.latitude, here.longitude);
    } catch (e) {
      debugPrint('Place capture failed: $e');
      return null;
    }
  }

  Future<List<NearbyPlayer>?> _nearby() async {
    try {
      final heard = await _radio.scan(scanDuration);
      if (heard == null) return null;
      final own = await _ownCode();
      final codes = heard.difference({?own});
      if (codes.isEmpty) return const [];

      final names = await _friendNames().timeout(
        const Duration(seconds: 3),
        onTimeout: () => const {},
      );
      final players = [
        for (final code in codes) NearbyPlayer(code: code, name: names[code]),
      ];
      // Friends first, by name; strangers after, by code.
      players.sort((a, b) {
        if ((a.name == null) != (b.name == null)) {
          return a.name == null ? 1 : -1;
        }
        return (a.name ?? a.code).toLowerCase().compareTo(
          (b.name ?? b.code).toLowerCase(),
        );
      });
      return players;
    } catch (e) {
      debugPrint('Nearby capture failed: $e');
      return null;
    }
  }
}
