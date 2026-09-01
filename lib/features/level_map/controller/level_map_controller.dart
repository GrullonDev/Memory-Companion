import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/level_map/controller/level_controller.dart';
import 'package:memory_companion/features/level_map/model/level_node.dart';

/// Los nodos del mapa de niveles.
///
/// Antes devolvía cuatro nodos escritos a mano que no tenían ninguna relación
/// con el sistema de niveles real: el jugador veía siempre lo mismo hiciera lo
/// que hiciera. Ahora se derivan del progreso guardado.
class LevelMapController extends AsyncNotifier<List<LevelNode>> {
  @override
  Future<List<LevelNode>> build() async {
    final levels = await ref.watch(userLevelsProvider.future);

    return [
      for (final level in levels)
        LevelNode(
          number: level.levelNumber,
          status: level.isCompleted
              ? LevelStatus.completed
              // Solo uno está desbloqueado y sin completar: ese es el actual.
              : level.isUnlocked
                  ? LevelStatus.current
                  : LevelStatus.locked,
        ),
    ];
  }
}

final levelMapControllerProvider =
    AsyncNotifierProvider<LevelMapController, List<LevelNode>>(
      LevelMapController.new,
    );
