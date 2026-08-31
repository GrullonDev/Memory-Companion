import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/widgets/async_value_view.dart';
import 'package:memory_companion/features/home/controller/home_controller.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/shop/controller/shop_controller.dart';
import 'package:memory_companion/features/shop/model/plan.dart';
import 'package:memory_companion/features/shop/model/plan_feature.dart';
import 'package:memory_companion/features/shop/widget/plan_card.dart';
import 'package:memory_companion/features/shop/widget/shop_hero_banner.dart';
import 'package:memory_companion/features/shop/widget/theme_chip.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  static const _themeIcons = [
    Icons.rocket_launch_rounded,
    Icons.cruelty_free_rounded,
    Icons.local_pizza_rounded,
    Icons.auto_awesome_rounded,
  ];

  void _upgrade(BuildContext context, WidgetRef ref) {
    ref.read(shopControllerProvider.notifier).upgrade(PlanId.pro);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocale.upgradeSuccessMessage.getString(context)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletControllerProvider);
    final summary = ref.watch(homeSummaryProvider);
    final shop = ref.watch(shopControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HomeBottomNav(
        activeIndex: 3,
        onTap: (index) => RoutePaths.navigateToTab(context, index),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            HomeTopBar(
              playerName: summary.playerName,
              coins: wallet.value ?? 0,
              onAvatarTap: () =>
                  Navigator.of(context).pushNamed(RoutePaths.profile),
            ),
            const SizedBox(height: 24),
            const ShopHeroBanner(),
            const SizedBox(height: 20),
            Text(
              AppLocale.shopHeroTitle.getString(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocale.shopHeroSubtitle.getString(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            AsyncValueView(
              value: shop,
              onRetry: () => ref.invalidate(shopControllerProvider),
              data: (context, shopState) => Column(
                children: [
                  for (final plan in shopState.plans) ...[
                    _PlanCardFromModel(
                      plan: plan,
                      isCurrent: plan.id == shopState.currentPlanId,
                      onUpgrade: () => _upgrade(context, ref),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppLocale.exclusiveThemesTitle.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _themeIcons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    ThemeChip(icon: _themeIcons[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCardFromModel extends StatelessWidget {
  const _PlanCardFromModel({
    required this.plan,
    required this.isCurrent,
    required this.onUpgrade,
  });

  final Plan plan;
  final bool isCurrent;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final highlighted = plan.id == PlanId.pro;
    return PlanCard(
      icon: plan.icon,
      title: plan.titleKey.getString(context),
      highlighted: highlighted,
      badge: plan.badgeKey == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                plan.badgeKey!.getString(context),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onPrimaryFixed,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      features: [
        for (final feature in plan.features)
          PlanFeature(
            label: feature.labelKey.getString(context),
            included: feature.included,
            icon: feature.icon,
          ),
      ],
      footer: isCurrent
          ? Center(
              child: Text(
                AppLocale.currentPlanLabel.getString(context),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onUpgrade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40E6B400),
                          offset: Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      AppLocale.upgradeNowLabel.getString(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onPrimaryFixed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
