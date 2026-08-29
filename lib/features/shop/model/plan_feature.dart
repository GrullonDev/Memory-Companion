import 'package:flutter/material.dart';

class PlanFeature {
  const PlanFeature({required this.label, required this.included, this.icon});

  final String label;
  final bool included;

  /// Overrides the default check/close icon — used by the Pro plan to
  /// show a feature-specific glyph (heart, palette, no-ads) instead.
  final IconData? icon;
}
