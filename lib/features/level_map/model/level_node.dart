enum LevelStatus { completed, current, locked }

/// A single stop on the solo-mode level path.
class LevelNode {
  const LevelNode({required this.number, required this.status});

  /// Nodes kept on the path below the current one, as a trail of progress.
  static const completedShown = 2;

  /// Locked nodes shown ahead of the current one, as something to reach for.
  static const lockedShown = 3;

  final int number;
  final LevelStatus status;

  bool get isPlayable => status != LevelStatus.locked;

  /// Where [number] stands for a player whose current level is
  /// [currentLevel]: every level before it has been won, the rest are ahead.
  static LevelStatus statusFor(int number, {required int currentLevel}) {
    if (number < currentLevel) return LevelStatus.completed;
    if (number == currentLevel) return LevelStatus.current;
    return LevelStatus.locked;
  }

  /// The window of the path around [currentLevel], lowest level first.
  ///
  /// The level is unbounded (it grows by one per board won), so the path
  /// slides with the player instead of listing every level. It always holds
  /// the same number of nodes, keeping the current one near the bottom of
  /// the map, where it is visible without scrolling.
  static List<LevelNode> pathAround(int currentLevel) {
    final current = currentLevel < 1 ? 1 : currentLevel;
    final first = current - completedShown < 1 ? 1 : current - completedShown;
    return [
      for (var n = first; n < first + completedShown + 1 + lockedShown; n++)
        LevelNode(
          number: n,
          status: statusFor(n, currentLevel: current),
        ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is LevelNode && other.number == number && other.status == status;

  @override
  int get hashCode => Object.hash(number, status);

  @override
  String toString() => 'LevelNode($number, ${status.name})';
}
