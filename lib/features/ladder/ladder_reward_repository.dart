import 'package:drift/drift.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/features/ladder/level_rewards.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

/// Entrega los premios de la escalera de niveles de cada juego.
///
/// Es idempotente: marca hasta qué nivel ya pagó (`ladder_rewards`) y suma
/// las monedas **en la misma transacción**, así que reclamar dos veces —o
/// que la app se cierre a medias— no puede pagar un peldaño dos veces ni
/// dejarlo marcado sin pagar.
class LadderRewardRepository {
  LadderRewardRepository({
    required AppDatabase database,
    required PlayerRepository playerRepository,
    DateTime Function()? clock,
  }) : _db = database,
       _playerRepository = playerRepository,
       _now = clock ?? DateTime.now;

  final AppDatabase _db;
  final PlayerRepository _playerRepository;
  final DateTime Function() _now;

  /// Paga los premios que [level] ha ganado en [ladderId] y los devuelve.
  ///
  /// [level] es el nivel que toca jugar: los completados son uno menos. Las
  /// escaleras nunca bajan, así que un [level] viejo simplemente no paga.
  Future<List<LevelReward>> claim({
    required String ladderId,
    required int level,
    required String playerLocalId,
  }) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.ladderRewards,
      )..where((l) => l.ladderId.equals(ladderId))).getSingleOrNull();
      final rewarded = row?.rewardedLevel ?? 0;
      final completed = level - 1;
      if (completed <= rewarded) return const <LevelReward>[];

      final rewards = LevelRewards.between(after: rewarded, upTo: completed);

      await _db
          .into(_db.ladderRewards)
          .insertOnConflictUpdate(
            LadderRewardsCompanion.insert(
              ladderId: ladderId,
              rewardedLevel: Value(completed),
              updatedAt: _now().millisecondsSinceEpoch,
            ),
          );

      final coins = rewards.fold<int>(0, (sum, r) => sum + r.coins);
      if (coins > 0) {
        await _playerRepository.earnCoins(
          localId: playerLocalId,
          amount: coins,
        );
      }
      return rewards;
    });
  }
}
