import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/adaptive_button.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/ads/controller/remove_ads_controller.dart';
import 'package:memory_companion/features/ads/controller/ad_controller.dart';
import 'package:memory_companion/features/ads/model/remove_ads_state.dart';

/// La compra "Sin anuncios": precio de la tienda, comprar y restaurar.
///
/// Una vez comprado solo queda el agradecimiento. En plataformas sin tienda
/// (escritorio, web) no se pinta nada.
class RemoveAdsCard extends ConsumerWidget {
  const RemoveAdsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(adsPlatformSupportedProvider)) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(removeAdsControllerProvider).value;
    final controller = ref.read(removeAdsControllerProvider.notifier);
    final purchased = state?.isPurchased ?? false;
    final product = state?.product;
    final busy = state == null || state.busy;

    final status = switch ((state, state?.message)) {
      (null, _) => AppLocale.removeAdsProcessingLabel,
      (_, final RemoveAdsMessage message) => _messageKey(message),
      (final RemoveAdsState s, null) when s.isPurchased =>
        AppLocale.removeAdsActiveLabel,
      (final RemoveAdsState s, null) when s.busy =>
        AppLocale.removeAdsProcessingLabel,
      (final RemoveAdsState s, null) when s.product == null =>
        AppLocale.removeAdsUnavailableLabel,
      _ => null,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: AppSize.wellMd,
                height: AppSize.wellMd,
                decoration: BoxDecoration(
                  color: AppColors.sunSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  purchased ? Icons.verified_rounded : Icons.block_rounded,
                  color: AppColors.sunStrong,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocale.removeAdsTitle.getString(context),
                      style: textTheme.titleMedium,
                    ),
                    Text(
                      AppLocale.removeAdsDescription.getString(context),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: Text(
                status.getString(context),
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
          if (!purchased) ...[
            const SizedBox(height: AppSpacing.md),
            AdaptiveButton(
              label: product == null
                  ? AppLocale.removeAdsTitle.getString(context)
                  : AppLocale.removeAdsBuyLabel
                        .getString(context)
                        .replaceAll('{price}', product.price),
              icon: Icons.block_rounded,
              onPressed: state != null && state.canBuy ? controller.buy : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            AdaptiveButton(
              label: AppLocale.removeAdsRestoreLabel.getString(context),
              icon: Icons.restore_rounded,
              variant: AdaptiveButtonVariant.neutral,
              onPressed: busy ? null : controller.restore,
            ),
          ],
        ],
      ),
    );
  }

  static String _messageKey(RemoveAdsMessage message) => switch (message) {
    RemoveAdsMessage.thanks => AppLocale.removeAdsThanksLabel,
    RemoveAdsMessage.purchaseFailed => AppLocale.removeAdsPurchaseFailedLabel,
    RemoveAdsMessage.restoreFailed => AppLocale.removeAdsRestoreFailedLabel,
    RemoveAdsMessage.nothingToRestore =>
      AppLocale.removeAdsNothingToRestoreLabel,
  };
}
