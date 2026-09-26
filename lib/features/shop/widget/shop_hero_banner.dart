import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';

/// Stylized stand-in for the promotional "Pro Plan Store" artwork — no such
/// illustration asset exists in the project, so this uses a flat gradient,
/// a glowing icon and text chips instead of painted art.
class ShopHeroBanner extends StatelessWidget {
  const ShopHeroBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondaryFixed, AppColors.secondaryFixedDim],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryFixed.withValues(alpha: 0.9),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FFE16D),
                  blurRadius: 30,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_objects_rounded,
              size: 48,
              color: AppColors.onPrimaryFixed,
            ),
          ),
          Positioned(
            top: 16,
            child: Text(
              AppLocale.shopHeroBanner.getString(context),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSecondaryFixed,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.mintGreen,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                AppLocale.activatePremiumLabel.getString(context),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onMintGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
