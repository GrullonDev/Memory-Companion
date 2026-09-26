import 'package:flutter/widgets.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';

/// "5 min ago" / "Hace 5 min" for [playedAt], in the current language.
///
/// Resolved while painting, not in a controller: it depends on both the
/// language and the current time, and a controller has neither context.
String timeAgoLabel(BuildContext context, DateTime playedAt, {DateTime? now}) {
  return formatTimeAgo(
    (now ?? DateTime.now()).difference(playedAt),
    (key) => key.getString(context),
  );
}

/// [timeAgoLabel] without a [BuildContext]: [translate] resolves an
/// [AppLocale] key. Split out so the thresholds can be tested alone.
String formatTimeAgo(Duration elapsed, String Function(String key) translate) {
  String n(String key, int value) => translate(key).replaceAll('{n}', '$value');

  if (elapsed.inMinutes < 1) return translate(AppLocale.timeAgoJustNow);
  if (elapsed.inHours < 1) {
    return n(AppLocale.timeAgoMinutes, elapsed.inMinutes);
  }
  if (elapsed.inDays < 1) return n(AppLocale.timeAgoHours, elapsed.inHours);
  if (elapsed.inDays < 7) return n(AppLocale.timeAgoDays, elapsed.inDays);
  if (elapsed.inDays < 30) {
    return n(AppLocale.timeAgoWeeks, elapsed.inDays ~/ 7);
  }
  final months = elapsed.inDays ~/ 30;
  return months == 1
      ? translate(AppLocale.timeAgoOneMonth)
      : n(AppLocale.timeAgoMonths, months);
}
