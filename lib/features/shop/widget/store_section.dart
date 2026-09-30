import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/localization/app_locale.dart';
import 'package:memory_companion/core/theme/app_colors.dart';
import 'package:memory_companion/core/theme/app_spacing.dart';
import 'package:memory_companion/core/widgets/app_card.dart';
import 'package:memory_companion/features/lives/controller/lives_controller.dart';
import 'package:memory_companion/features/shop/controller/store_controller.dart';
import 'package:memory_companion/features/shop/model/store_item.dart';
import 'package:memory_companion/features/statistics/widget/stats_format.dart';
import 'package:memory_companion/features/wallet/controller/wallet_controller.dart';

/// Where the coins earned by playing are spent: every [StoreItem], its
/// price, how many the player holds and a buy button that is only live
/// when the purchase can go through.
class StoreSection extends ConsumerStatefulWidget {
  const StoreSection({super.key});

  @override
  ConsumerState<StoreSection> createState() => _StoreSectionState();
}

class _StoreSectionState extends ConsumerState<StoreSection> {
  StoreItem? _buying;

  Future<void> _buy(StoreItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final title = item.titleKey.getString(context);
    final messages = {
      PurchaseResult.purchased: fill(
        AppLocale.storePurchasedMessage.getString(context),
        title,
      ),
      PurchaseResult.notEnoughCoins: AppLocale.storeNotEnoughCoins.getString(
        context,
      ),
      PurchaseResult.limitReached: AppLocale.storeLimitReached.getString(
        context,
      ),
      PurchaseResult.notNeeded: AppLocale.storeNotNeeded.getString(context),
    };
    setState(() => _buying = item);
    final result = await ref.read(storeServiceProvider).buy(item);
    if (!mounted) return;
    setState(() => _buying = null);
    messenger.showSnackBar(SnackBar(content: Text(messages[result]!)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coins = ref.watch(walletControllerProvider).value ?? 0;
    final inventory = ref.watch(inventoryProvider).value ?? const {};
    final lives = ref.watch(livesControllerProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocale.storeTitle.getString(context),
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppLocale.storeSubtitle.getString(context),
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in StoreItem.values) ...[
          _StoreItemCard(
            item: item,
            owned: item.grants == null ? null : inventory[item.grants] ?? 0,
            busy: _buying == item,
            enabled:
                _buying == null &&
                coins >= item.price &&
                switch (item) {
                  StoreItem.livesRefill =>
                    lives != null && lives.current < lives.max,
                  _ =>
                    item.maxOwned == null ||
                        (inventory[item.grants] ?? 0) < item.maxOwned!,
                },
            onBuy: () => _buy(item),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _StoreItemCard extends StatelessWidget {
  const _StoreItemCard({
    required this.item,
    required this.owned,
    required this.busy,
    required this.enabled,
    required this.onBuy,
  });

  final StoreItem item;

  /// How many the player holds; null for items used on purchase.
  final int? owned;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final max = item.maxOwned;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: AppSize.wellMd,
            height: AppSize.wellMd,
            decoration: BoxDecoration(
              color: AppColors.sunSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: AppColors.sunStrong),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleKey.getString(context),
                  style: textTheme.titleMedium,
                ),
                Text(
                  item.descriptionKey.getString(context),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (owned != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      max == null
                          ? fill(AppLocale.storeOwnedLabel.getString(context), owned!)
                          : fill(
                              AppLocale.storeOwnedOfLabel.getString(context),
                              owned!,
                            ).replaceAll('{total}', '$max'),
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.skyStrong,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: enabled ? onBuy : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sun,
              foregroundColor: AppColors.onSun,
              minimumSize: const Size(0, AppSize.touchMin),
            ),
            icon: busy
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.monetization_on_rounded, size: 18),
            label: Text(
              '${item.price}',
              semanticsLabel: fill(
                AppLocale.storeBuyForLabel.getString(context),
                item.price,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
