import 'package:flutter/widgets.dart';

enum PlanId { free, pro }

/// A single feature row for a [Plan], expressed as an [AppLocale] key so it
/// can be resolved with `.getString(context)` where a [BuildContext] is
/// available (the controller that builds [Plan]s has none).
class PlanFeatureSpec {
  const PlanFeatureSpec({
    required this.labelKey,
    required this.included,
    this.icon,
  });

  final String labelKey;
  final bool included;
  final IconData? icon;
}

/// A subscription tier shown on the Shop screen.
class Plan {
  const Plan({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.features,
    this.badgeKey,
  });

  final PlanId id;
  final IconData icon;
  final String titleKey;
  final List<PlanFeatureSpec> features;
  final String? badgeKey;
}
