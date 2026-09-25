import 'dart:math' as math;

import 'package:memory_companion/core/database/app_database.dart';

/// A place the player plays at, as the settings and the history show it.
class Place {
  const Place({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.name,
  });

  factory Place.fromRow(PlaceRow row) => Place(
    id: row.id,
    name: row.name,
    latitude: row.latitude,
    longitude: row.longitude,
  );

  final int id;

  /// Null until the player names it.
  final String? name;
  final double latitude;
  final double longitude;

  bool get isNamed => name != null && name!.trim().isNotEmpty;
}

/// Great-circle distance in meters. Good to a few meters at the distances
/// places are grouped by, and needs no plugin, so it runs in unit tests.
double distanceInMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadius * math.asin(math.sqrt(a));
}
