import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/daily_reward/model/daily_reward.dart';
import 'package:memory_companion/features/daily_reward/repository/daily_reward_repository.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// The clock the daily reward reads. Overridden in tests.
final dailyRewardClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final dailyRewardRepositoryProvider = Provider<DailyRewardRepository>((ref) {
  return DailyRewardRepository(
    database: ref.watch(appDatabaseProvider),
    playerRepository: ref.watch(playerRepositoryProvider),
    clock: ref.watch(dailyRewardClockProvider),
  );
});

/// Today's reward for the local player, and the action to claim it.
///
/// Follows the local database, so a claim shows up without any `state =`
/// here, like the wallet.
class DailyRewardController extends StreamNotifier<DailyRewardStatus> {
  @override
  Stream<DailyRewardStatus> build() async* {
    // Only the id: coins changing must not resubscribe the stream.
    final localId = await ref.watch(
      localPlayerProvider.selectAsync((player) => player.localId),
    );

    // Nothing in the database changes at midnight, but the reward does.
    final now = ref.read(dailyRewardClockProvider)();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final rollover = Timer(midnight.difference(now), ref.invalidateSelf);
    ref.onDispose(rollover.cancel);

    yield* ref.watch(dailyRewardRepositoryProvider).watchStatus(localId);
  }

  /// Claims today's reward. Null if there was nothing to claim.
  Future<DailyRewardClaim?> claim() async {
    final localId = ref.read(localPlayerProvider).value?.localId;
    if (localId == null) return null;
    return ref
        .read(dailyRewardRepositoryProvider)
        .claim(playerLocalId: localId);
  }
}

final dailyRewardControllerProvider =
    StreamNotifierProvider<DailyRewardController, DailyRewardStatus>(
      DailyRewardController.new,
    );
