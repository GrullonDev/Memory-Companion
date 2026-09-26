enum MatchResult { win, loss }

class ProfileMatch {
  const ProfileMatch({
    required this.title,
    required this.score,
    required this.moves,
    required this.playedAt,
    required this.result,
  });

  final String title;
  final String score;
  final int moves;

  /// Shown relative to now ("2 h ago") and in the current language, so it
  /// is formatted while painting.
  final DateTime playedAt;
  final MatchResult result;
}
