enum MatchResult { win, loss }

class ProfileMatch {
  const ProfileMatch({
    required this.title,
    required this.score,
    required this.moves,
    required this.timeAgo,
    required this.result,
  });

  final String title;
  final String score;
  final int moves;
  final String timeAgo;
  final MatchResult result;
}
