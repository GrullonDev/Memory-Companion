import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/daily_challenge/model/daily_challenge.dart';
import 'package:memory_companion/features/daily_challenge/repository/daily_challenge_repository.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

/// The device clock. Overridden in tests to pin "today".
final dailyClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>(
  (ref) => DailyChallengeRepository(
    database: ref.watch(appDatabaseProvider),
    clock: ref.watch(dailyClockProvider),
  ),
);

/// Today's challenge, computed from the local date: no network involved.
///
/// Recomputed whenever something re-reads it, so returning to the Home
/// after midnight shows the new day's challenge.
final todayChallengeProvider = Provider.autoDispose<DailyChallenge>(
  (ref) => DailyChallenge.forDate(ref.watch(dailyClockProvider)()),
);

/// Whether [challenge] is done, its result, and the current streak.
///
/// Keyed by challenge so an open result screen keeps its own day even if
/// the date rolls over while it is showing.
final dailyStatusProvider = StreamProvider.autoDispose
    .family<DailyStatus, DailyChallenge>((ref, challenge) async* {
      final player = await ref.watch(localPlayerProvider.future);
      yield* ref
          .watch(dailyChallengeRepositoryProvider)
          .watch(
            playerId: player.localId,
            dateKey: challenge.dateKey,
            number: challenge.number,
          );
    });
