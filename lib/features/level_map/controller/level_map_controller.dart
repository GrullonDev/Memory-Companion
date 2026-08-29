import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/level_map/model/level_node.dart';

/// Loads the levels for a region's level-select map.
class LevelMapController extends AsyncNotifier<List<LevelNode>> {
  @override
  Future<List<LevelNode>> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const [
      LevelNode(number: 1, status: LevelStatus.completed),
      LevelNode(number: 2, status: LevelStatus.current),
      LevelNode(number: 3, status: LevelStatus.locked),
      LevelNode(number: 4, status: LevelStatus.locked),
    ];
  }
}

final levelMapControllerProvider =
    AsyncNotifierProvider<LevelMapController, List<LevelNode>>(
      LevelMapController.new,
    );
