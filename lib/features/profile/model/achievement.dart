import 'package:flutter/material.dart';

class Achievement {
  const Achievement({
    required this.icon,
    required this.titleKey,
    required this.unlocked,
  });

  final IconData icon;

  /// An [AppLocale] key, resolved while painting.
  final String titleKey;
  final bool unlocked;
}
