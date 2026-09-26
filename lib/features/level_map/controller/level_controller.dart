import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/level_map/model/level.dart';
import 'package:memory_companion/features/level_map/repository/local_level_repository.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';

final localLevelRepositoryProvider = Provider<LocalLevelRepository>((ref) {
  return LocalLevelRepository(database: ref.watch(appDatabaseProvider));
});

/// Los niveles del jugador, con su progreso.
///
/// Conserva el nombre que ya usaban las pantallas, pero la fuente cambió: sale
/// de SQLite en lugar de Firestore, así que un jugador sin cuenta ve su
/// progreso real y no una lista vacía.
final userLevelsProvider = StreamProvider<List<GameLevel>>((ref) async* {
  ref.keepAlive();
  final player = await ref.watch(localPlayerProvider.future);
  yield* ref.watch(localLevelRepositoryProvider).watchLevels(player.localId);
});

/// El nivel que le toca jugar.
final currentLevelProvider = FutureProvider<int>((ref) async {
  final player = await ref.watch(localPlayerProvider.future);
  return ref.watch(localLevelRepositoryProvider).currentLevelNumber(
        player.localId,
      );
});

/// El nivel que el jugador acaba de elegir en el mapa.
///
/// Lo fija el mapa justo antes de navegar al tablero, y lo lee
/// [BoardController] al arrancar la partida. Se prefiere a un argumento de
/// ruta porque el tablero también lo necesita al reintentar, cuando ya no hay
/// navegación de por medio.
class SelectedLevel extends Notifier<int> {
  @override
  int build() => 1;

  void select(int levelNumber) {
    state = levelNumber < 1 ? 1 : levelNumber;
  }
}

final selectedLevelProvider = NotifierProvider<SelectedLevel, int>(
  SelectedLevel.new,
);

/// Operaciones sobre el progreso de niveles.
class LevelController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Marca un nivel como completado. Escritura local, sin cuenta ni red.
  Future<void> completeLevel({
    required int levelNumber,
    required int score,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final player = await ref.read(localPlayerProvider.future);
      await ref.read(localLevelRepositoryProvider).completeLevel(
            playerLocalId: player.localId,
            levelNumber: levelNumber,
            score: score,
          );
    });
  }
}

final levelControllerProvider = AsyncNotifierProvider<LevelController, void>(
  LevelController.new,
);
