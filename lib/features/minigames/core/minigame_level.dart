import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/ladder/ladder_controller.dart';
import 'package:memory_companion/features/minigames/core/base_minigame.dart';

/// A level every mini-game deals instead of the player's own. Duels pin it
/// so both sides face the same difficulty, and tests pin it so they never
/// open the real database.
final minigameLevelOverrideProvider = Provider<int?>((ref) => null);

/// The level [game] is dealt at: its ladder level (1 plus rounds won), which
/// has no top. Every module turns it into its own difficulty — longer
/// lists, bigger grids, less time — so the game keeps getting harder for as
/// long as the player keeps winning.
///
/// Reads 1 while the stats are still loading. Controllers `listen` to it in
/// `build`, so it has loaded by the time the player taps "start".
final minigameLevelProvider = Provider.family<int, BaseMinigame>((ref, game) {
  final pinned = ref.watch(minigameLevelOverrideProvider);
  if (pinned != null) return pinned;
  final wins = ref.watch(winsByStatsKeyProvider).value ?? const {};
  return minigameLevel(game, wins);
});

/// Linear growth from [start], one [step] every [every] levels, never past
/// [max]. The shape almost every difficulty knob below follows.
int levelRamp(
  int level, {
  required int start,
  required int max,
  int step = 1,
  int every = 1,
}) {
  final grown = start + ((level < 1 ? 0 : level - 1) ~/ every) * step;
  if (step >= 0) return grown > max ? max : grown;
  return grown < max ? max : grown;
}
