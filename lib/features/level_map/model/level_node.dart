enum LevelStatus { completed, current, locked }

/// A single stop on the solo-mode level path.
class LevelNode {
  const LevelNode({required this.number, required this.status});

  final int number;
  final LevelStatus status;

  bool get isPlayable => status != LevelStatus.locked;
}
