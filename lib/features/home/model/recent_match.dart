/// A single row in the home screen's "recent matches" list.
///
/// [titleKey] and [timeAgoKey] are [AppLocale] keys, resolved with
/// `.getString(context)` at render time.
class RecentMatch {
  const RecentMatch({
    required this.titleKey,
    required this.score,
    required this.timeAgoKey,
  });

  final String titleKey;
  final String score;
  final String timeAgoKey;
}
