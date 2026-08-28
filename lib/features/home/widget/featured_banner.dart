import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

class FeaturedBanner extends StatelessWidget {
  const FeaturedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.secondaryFixed,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset('assets/logo_mascota.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocale.bannerEyebrow.getString(context),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onSecondaryFixed.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocale.bannerHeadline.getString(context),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSecondaryFixed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(RoutePaths.levelMap),
              icon: const Icon(Icons.play_arrow, color: AppColors.onPrimaryFixed),
              label: Text(
                AppLocale.startGame.getString(context),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onPrimaryFixed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryFixed,
                minimumSize: const Size.fromHeight(56),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BannerChip(
                icon: Icons.play_arrow,
                label: AppLocale.chipArcade.getString(context),
              ),
              _BannerChip(
                icon: Icons.star,
                label: AppLocale.chipAchievements.getString(context),
                background: AppColors.mintGreen,
                foreground: AppColors.onMintGreen,
              ),
              _BannerChip(
                icon: Icons.card_giftcard,
                label: AppLocale.chipDailyRewards.getString(context),
                background: AppColors.tertiaryContainer,
                foreground: AppColors.onTertiaryContainer,
              ),
              _BannerChip(
                icon: Icons.settings,
                label: AppLocale.chipSettings.getString(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({
    required this.icon,
    required this.label,
    this.background = AppColors.surfaceContainerLowest,
    this.foreground = AppColors.secondary,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
