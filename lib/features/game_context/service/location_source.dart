import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

typedef Coordinates = ({double latitude, double longitude});

/// Where the device is, if the player allowed it.
abstract interface class LocationSource {
  /// Asks for the permission if it has not been answered yet. True when the
  /// app may read the location. Never opens the system settings on its own.
  Future<bool> requestPermission();

  /// The current position, or null when it cannot be read quickly: no
  /// permission, location off, or no fix inside the time limit. Never
  /// prompts.
  Future<Coordinates?> current();
}

/// [LocationSource] over `geolocator`.
///
/// Low accuracy on purpose: grouping games into places needs about a
/// hundred meters, and a coarse fix is faster, cheaper on battery and
/// reveals less.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  static const Duration timeLimit = Duration(seconds: 5);

  @override
  Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return _granted(permission);
    } catch (e) {
      debugPrint('Location permission failed: $e');
      return false;
    }
  }

  @override
  Future<Coordinates?> current() async {
    try {
      if (!_granted(await Geolocator.checkPermission())) return null;
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: timeLimit,
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      // A timeout indoors is normal; the last fix is still a fair guess of
      // where the game was played.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        return (latitude: last.latitude, longitude: last.longitude);
      } catch (_) {
        return null;
      }
    }
  }

  static bool _granted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}
