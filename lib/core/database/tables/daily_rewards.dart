import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/tables/player_profiles.dart';

/// El cofre diario: cuándo se reclamó por última vez y la racha de días
/// seguidos reclamándolo.
///
/// Es una racha **distinta** de la de `player_profiles`: aquella cuenta días
/// jugados, esta cuenta días en que se abrió el cofre. Separarlas evita que
/// reclamar el premio sostenga la racha de juego sin jugar.
///
/// **Solo local**: las monedas y el XP del premio viajan a la nube como
/// cualquier otro ingreso, en incrementos por la cola de sincronización.
@DataClassName('DailyRewardRow')
class DailyRewards extends Table {
  TextColumn get playerLocalId => text().references(PlayerProfiles, #localId)();

  /// Último día reclamado como `'YYYY-MM-DD'` en zona **local**, igual que
  /// `player_profiles.last_played_date` y por la misma razón.
  TextColumn get lastClaimDate => text().nullable()();

  IntColumn get claimStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestClaimStreak =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalClaims => integer().withDefault(const Constant(0))();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {playerLocalId};
}
