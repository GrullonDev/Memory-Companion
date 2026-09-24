import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/game_context/model/place.dart';

/// Groups game locations into places, on this device only.
///
/// A game played within [radiusMeters] of a known place belongs to it;
/// anywhere else starts a new one. Places are what the history and the
/// search talk about, so a house and the park two streets away stay apart,
/// while GPS jitter inside the house does not create a second "home".
class PlaceRepository {
  PlaceRepository({required AppDatabase database, DateTime Function()? clock})
    : _db = database,
      _now = clock ?? DateTime.now;

  static const double radiusMeters = 150;

  final AppDatabase _db;
  final DateTime Function() _now;

  /// The place [latitude], [longitude] belongs to, created if it is new.
  Future<int> resolve(double latitude, double longitude) {
    return _db.transaction(() async {
      final places = await _db.select(_db.places).get();
      PlaceRow? nearest;
      var nearestDistance = double.infinity;
      for (final place in places) {
        final distance = distanceInMeters(
          latitude,
          longitude,
          place.latitude,
          place.longitude,
        );
        if (distance < nearestDistance) {
          nearest = place;
          nearestDistance = distance;
        }
      }
      if (nearest != null && nearestDistance <= radiusMeters) {
        return nearest.id;
      }
      return _db
          .into(_db.places)
          .insert(
            PlacesCompanion.insert(
              latitude: _round(latitude),
              longitude: _round(longitude),
              createdAt: _now().millisecondsSinceEpoch,
            ),
          );
    });
  }

  /// Oldest first, so "Lugar 1" keeps its number as places are added.
  Stream<List<Place>> watchAll() => _all().watch().map(_toPlaces);

  Future<List<Place>> readAll() async => _toPlaces(await _all().get());

  /// Names a place. A blank [name] clears it back to "Lugar N".
  Future<void> rename(int id, String name) {
    final trimmed = name.trim();
    return (_db.update(_db.places)..where((p) => p.id.equals(id))).write(
      PlacesCompanion(name: Value(trimmed.isEmpty ? null : trimmed)),
    );
  }

  SimpleSelectStatement<$PlacesTable, PlaceRow> _all() =>
      _db.select(_db.places)..orderBy([(p) => OrderingTerm.asc(p.id)]);

  static List<Place> _toPlaces(List<PlaceRow> rows) => [
    for (final row in rows) Place.fromRow(row),
  ];

  /// Four decimals: about 10 m. Enough to group games, no finer.
  static double _round(double degrees) =>
      (degrees * 10000).roundToDouble() / 10000;
}
