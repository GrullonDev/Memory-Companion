import 'package:drift/drift.dart';

/// Un lugar donde el jugador suele jugar: el centro de un grupo de
/// partidas cercanas entre sí.
///
/// **Solo local**, como `GameStats`: no sale nunca del dispositivo. Las
/// partidas no guardan coordenadas propias, solo el [id] del lugar al que
/// pertenecen, así que el historial no es un rastro de posiciones. El centro
/// se guarda redondeado a unos 10 m, que basta para agrupar y no dice más.
@DataClassName('PlaceRow')
class Places extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Lo que el jugador le puso ("Casa", "Parque"). Null hasta que lo nombra;
  /// mientras tanto la app lo muestra como "Lugar N".
  TextColumn get name => text().nullable()();

  RealColumn get latitude => real()();
  RealColumn get longitude => real()();

  IntColumn get createdAt => integer()();
}
