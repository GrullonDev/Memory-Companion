import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:memory_companion/core/localization/app_locale.dart';

/// A key missing from one language renders as "`key` not found" on screen.
/// A merge of develop dropped several once («saveStateOnDevice not found» on
/// the Home); these checks make that a failing test instead of a QA report.
void main() {
  // The declared keys can only be listed from the source: Dart has no
  // reflection over a mixin's constants.
  final declared = RegExp(r"static const String (\w+) = '(\w+)';")
      .allMatches(
        File('lib/core/localization/app_locale.dart').readAsStringSync(),
      )
      .map((m) => (name: m.group(1)!, value: m.group(2)!))
      .toList();

  test('the source parse found the keys', () {
    expect(declared.length, greaterThan(400));
  });

  test('every key is named after itself', () {
    // `foo = 'bar'` would look up "bar" and miss.
    final mismatched = [
      for (final k in declared)
        if (k.name != k.value) k.name,
    ];
    expect(mismatched, isEmpty);
  });

  for (final (language, map) in [('es', AppLocale.es), ('en', AppLocale.en)]) {
    test('$language translates every declared key', () {
      final missing = [
        for (final k in declared)
          if (!map.containsKey(k.value)) k.value,
      ];
      expect(missing, isEmpty);
    });

    test('$language has no empty translations', () {
      final empty = [
        for (final e in map.entries)
          if (e.value.toString().trim().isEmpty) e.key,
      ];
      expect(empty, isEmpty);
    });
  }

  test('both languages have exactly the same keys', () {
    expect(AppLocale.es.keys.toSet(), AppLocale.en.keys.toSet());
  });

  test('both languages use the same placeholders', () {
    final placeholder = RegExp(r'\{\w+\}');
    Set<String> of(Object? text) =>
        placeholder.allMatches(text.toString()).map((m) => m.group(0)!).toSet();

    final differing = [
      for (final key in AppLocale.es.keys)
        if (!setEquals(of(AppLocale.es[key]), of(AppLocale.en[key]))) key,
    ];
    expect(differing, isEmpty);
  });
}

bool setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);
