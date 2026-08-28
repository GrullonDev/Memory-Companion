import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/features/shop/model/plan.dart';

/// Which plan the player currently owns, plus the catalog of plans on
/// offer. Real payments aren't wired up — [ShopController.upgrade] just
/// flips the current plan, standing in for a completed purchase.
class ShopState {
  const ShopState({required this.plans, required this.currentPlanId});

  final List<Plan> plans;
  final PlanId currentPlanId;

  ShopState copyWith({PlanId? currentPlanId}) {
    return ShopState(
      plans: plans,
      currentPlanId: currentPlanId ?? this.currentPlanId,
    );
  }
}

class ShopController extends AsyncNotifier<ShopState> {
  @override
  Future<ShopState> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const ShopState(
      currentPlanId: PlanId.free,
      plans: [
        Plan(
          id: PlanId.free,
          icon: Icons.sentiment_satisfied_alt_rounded,
          titleKey: AppLocale.planFreeTitle,
          features: [
            PlanFeatureSpec(labelKey: AppLocale.featLivesDaily, included: true),
            PlanFeatureSpec(
              labelKey: AppLocale.featBasicThemes,
              included: true,
            ),
            PlanFeatureSpec(
              labelKey: AppLocale.featAdSupported,
              included: false,
            ),
          ],
        ),
        Plan(
          id: PlanId.pro,
          icon: Icons.star_rounded,
          titleKey: AppLocale.planProTitle,
          badgeKey: AppLocale.bestValueLabel,
          features: [
            PlanFeatureSpec(
              labelKey: AppLocale.featInfiniteLives,
              included: true,
              icon: Icons.favorite_rounded,
            ),
            PlanFeatureSpec(
              labelKey: AppLocale.featExclusiveThemes,
              included: true,
              icon: Icons.palette_rounded,
            ),
            PlanFeatureSpec(
              labelKey: AppLocale.featNoAds,
              included: true,
              icon: Icons.block_rounded,
            ),
          ],
        ),
      ],
    );
  }

  /// Simulates purchasing [planId] — no payment backend exists yet.
  void upgrade(PlanId planId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(currentPlanId: planId));
  }
}

final shopControllerProvider = AsyncNotifierProvider<ShopController, ShopState>(
  ShopController.new,
);
