import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_stat_chip.dart';
import 'package:memory_companion/features/ads/widget/remove_ads_card.dart';
import 'package:memory_companion/features/shop/widget/store_section.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// The coin store on its own page, so it is reachable while the plans
/// shop (the hidden Shop tab) is still in development.
class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(walletControllerProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(AppLocale.storeTitle.getString(context)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.screenMargin),
            child: AppStatChip.coins(
              value: NumberFormat.decimalPattern().format(coins),
              semanticLabel:
                  '${AppLocale.coinsSemanticLabel.getString(context)}: $coins',
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenMargin,
                AppSpacing.sm,
                AppSpacing.screenMargin,
                AppSpacing.xxl,
              ),
              children: const [
                RemoveAdsCard(),
                SizedBox(height: AppSpacing.md),
                StoreSection(showTitle: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
