import 'package:flutter/material.dart';

class Achievement {
  const Achievement({
    required this.icon,
    required this.title,
    required this.unlocked,
  });

  final IconData icon;
  final String title;
  final bool unlocked;
}
