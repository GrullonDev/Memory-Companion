import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/features/home/widget/home_bottom_nav.dart';
import 'package:memory_companion/features/home/widget/home_top_bar.dart';
import 'package:memory_companion/features/shop/model/plan_feature.dart';
import 'package:memory_companion/features/shop/widget/plan_card.dart';
import 'package:memory_companion/features/shop/widget/shop_hero_banner.dart';
import 'package:memory_companion/features/shop/widget/theme_chip.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  static const _themeIcons = [
    Icons.rocket_launch_rounded,
    Icons.cruelty_free_rounded,
    Icons.local_pizza_rounded,
    Icons.auto_awesome_rounded,
  ];

  @override
  Widget build(BuildContext context) {
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
              coins: 1250,
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            PlanCard(
              icon: Icons.sentiment_satisfied_alt_rounded,
              title: AppLocale.planFreeTitle.getString(context),
              features: [
                PlanFeature(
                  label: AppLocale.featLivesDaily.getString(context),
                  included: true,
                ),
                PlanFeature(
                  label: AppLocale.featBasicThemes.getString(context),
                  included: true,
                ),
                PlanFeature(
                  label: AppLocale.featAdSupported.getString(context),
                  included: false,
                ),
              ],
              footer: Center(
                child: Text(
                  AppLocale.currentPlanLabel.getString(context),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            PlanCard(
              icon: Icons.star_rounded,
              title: AppLocale.planProTitle.getString(context),
              highlighted: true,
              badge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  AppLocale.bestValueLabel.getString(context),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onPrimaryFixed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              features: [
                PlanFeature(
                  icon: Icons.favorite_rounded,
                  label: AppLocale.featInfiniteLives.getString(context),
                  included: true,
                ),
                PlanFeature(
                  icon: Icons.palette_rounded,
                  label: AppLocale.featExclusiveThemes.getString(context),
                  included: true,
                ),
                PlanFeature(
                  icon: Icons.block_rounded,
                  label: AppLocale.featNoAds.getString(context),
                  included: true,
                ),
              ],
              footer: SizedBox(
                width: double.infinity,
                child: Material(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
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
            ),
            const SizedBox(height: 24),
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
