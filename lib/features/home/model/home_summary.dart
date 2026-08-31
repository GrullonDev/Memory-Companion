/// XP required to clear [level] and reach the next one.
///
/// Kept as a single function so the Home and the Profile can never disagree
/// about how far along a player is.
int xpTargetForLevel(int level) => 1000 * (level < 1 ? 1 : level);

/// Everything the Home header needs about the player, in one immutable
/// snapshot: who they are, how far along they are, and how many days in a
/// row they have shown up.
///
/// Read-only view over the Firestore user document — it computes nothing the
/// backend does not already store, so nothing here can invent progress.
class HomeSummary {
  const HomeSummary({
    required this.playerName,
    required this.level,
    required this.currentXp,
    required this.streakDays,
    required this.isLoading,
  });

  const HomeSummary.empty({this.isLoading = false})
      : playerName = '',
        level = 1,
        currentXp = 0,
        streakDays = 0;

  /// Display name, or an empty string when the profile has not loaded yet.
  final String playerName;
  final int level;
  final int currentXp;

  /// Consecutive days played. 0 means the player has no streak to protect,
  /// which the UI treats as an invitation rather than a failure.
  final int streakDays;

  final bool isLoading;

  int get targetXp => xpTargetForLevel(level);

  /// 0.0 – 1.0 progress toward the next level.
  double get xpProgress {
    final target = targetXp;
    if (target <= 0) return 0;
    return (currentXp / target).clamp(0.0, 1.0);
  }

  int get xpRemaining {
    final remaining = targetXp - currentXp;
    return remaining < 0 ? 0 : remaining;
  }

  int get nextLevel => level + 1;

  bool get hasStreak => streakDays > 0;
}
