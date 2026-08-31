/// A single row in the home screen's "recent matches" list.
///
/// [titleKey] and [timeAgoKey] are [AppLocale] keys, resolved with
/// `.getString(context)` at render time.
class RecentMatch {
  const RecentMatch({
    required this.titleKey,
    required this.score,
    required this.timeAgoKey,
    this.isPlaceholder = false,
  });

  final String titleKey;
  final String score;
  final String timeAgoKey;

  /// True when the player has not finished a match yet, so the Home can show
  /// an inviting empty state instead of a row of dashes.
  final bool isPlaceholder;
}
