/// A single row in the home screen's "recent matches" list.
///
/// [titleKey] sí es una clave de [AppLocale] y se resuelve al pintar.
/// [timeAgo] no: llega ya formateado ("hace 2 h"), porque depende de la hora
/// actual y no de una tabla de traducciones. Antes ambos se pasaban por
/// `.getString(context)`, que resolvía como clave un texto que no lo era.
class RecentMatch {
  const RecentMatch({
    required this.titleKey,
    required this.score,
    required this.timeAgo,
    this.isPlaceholder = false,
  });

  final String titleKey;
  final String score;
  final String timeAgo;

  /// True when the player has not finished a match yet, so the Home can show
  /// an inviting empty state instead of a row of dashes.
  final bool isPlaceholder;
}
