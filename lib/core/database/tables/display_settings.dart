import 'package:drift/drift.dart';

import 'package:memory_companion/core/theme/visual_profile.dart';

/// Preferencias de presentación del dispositivo. Una sola fila.
///
/// Son del **dispositivo**, no del jugador: no referencian a
/// `PlayerProfiles` y no pasan por la cola de sincronización. Quien configura
/// la tablet de su madre en modo accesible no quiere que su propio teléfono
/// cambie al vincular la misma cuenta. Tampoco dependen de que exista un
/// perfil: el tema tiene que resolverse ya durante el splash.
@DataClassName('DisplaySettingsRow')
class DisplaySettings extends Table {
  /// Siempre `DisplaySettingsRepository.singletonId`. Existe solo para que
  /// el upsert tenga clave.
  IntColumn get id => integer()();

  TextColumn get visualProfile => textEnum<VisualProfile>().withDefault(
    Constant(VisualProfile.vibrant.name),
  )();

  /// Si la partida corre contra el reloj. Se reinicia al valor por defecto
  /// del perfil cada vez que se elige uno, y después el jugador manda.
  BoolColumn get timedMatches => boolean().withDefault(const Constant(true))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
