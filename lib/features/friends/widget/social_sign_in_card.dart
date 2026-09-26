import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/routes/route_paths.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/app_card.dart';

/// Shown on Friends and Versus to players without an account: friends have
/// to be able to find you, and that needs one.
class SocialSignInCard extends StatelessWidget {
  const SocialSignInCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.groups_rounded,
            size: 56,
            color: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocale.socialSignInTitle.getString(context),
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppLocale.socialSignInMessage.getString(context),
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AdaptiveButton(
            label: AppLocale.createAccountLabel.getString(context),
            icon: Icons.person_add_alt_1_rounded,
            onPressed: () =>
                Navigator.of(context).pushNamed(RoutePaths.register),
          ),
        ],
      ),
    );
  }
}
