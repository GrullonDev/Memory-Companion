import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/localization/time_ago.dart';

void main() {
  String es(Duration elapsed) =>
      formatTimeAgo(elapsed, (key) => AppLocale.es[key] as String);
  String en(Duration elapsed) =>
      formatTimeAgo(elapsed, (key) => AppLocale.en[key] as String);

  test('each range in both languages', () {
    expect(es(const Duration(seconds: 30)), 'Hace unos segundos');
    expect(en(const Duration(seconds: 30)), 'Just now');
    expect(es(const Duration(minutes: 5)), 'Hace 5 min');
    expect(en(const Duration(minutes: 5)), '5 min ago');
    expect(en(const Duration(hours: 3)), '3 h ago');
    expect(en(const Duration(days: 2)), '2 d ago');
    expect(es(const Duration(days: 15)), 'Hace 2 sem');
    expect(en(const Duration(days: 15)), '2 wk ago');
  });

  test('months are never confused with minutes, and 1 is singular', () {
    // The old profile formatter wrote "Hace 2m" for both.
    expect(es(const Duration(days: 35)), 'Hace 1 mes');
    expect(en(const Duration(days: 35)), '1 month ago');
    expect(es(const Duration(days: 65)), 'Hace 2 meses');
    expect(en(const Duration(days: 65)), '2 months ago');
  });
}
