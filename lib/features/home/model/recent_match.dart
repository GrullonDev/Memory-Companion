/// A single row in the home screen's "recent matches" list.
///
/// [titleKey] es una clave de [AppLocale] y se resuelve al pintar. De
/// [playedAt] sale "hace 2 h" también al pintar (`timeAgoLabel`), porque
/// depende del idioma y de la hora actual, y el controlador no tiene
/// ninguno de los dos.
class RecentMatch {
  const RecentMatch({
    required this.titleKey,
    required this.score,
    this.playedAt,
    this.isPlaceholder = false,
  });

  final String titleKey;
  final String score;

  /// Null for the placeholder.
  final DateTime? playedAt;

  /// True when the player has not finished a match yet, so the Home can show
  /// an inviting empty state instead of a row of dashes.
  final bool isPlaceholder;
}
