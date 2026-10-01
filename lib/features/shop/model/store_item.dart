import 'package:flutter/material.dart';

import 'package:memory_companion/core/localization/app_locale.dart';

/// Something the player can hold in the inventory until they use it.
///
/// `name` is the `inventory_items.item_id`: never rename a value once
/// shipped.
enum InventoryKind {
  /// Covers one missed day so the play streak does not break.
  streakFreeze,

  /// Reveals a cell in the sudoku once the free hints are spent.
  hint,
}

/// What the store sells for coins.
///
/// Each item either adds to the inventory ([grants] × [quantity]) or takes
/// effect at once (the lives refill, which has no [grants]).
enum StoreItem {
  streakFreeze(
    icon: Icons.ac_unit_rounded,
    titleKey: AppLocale.storeStreakFreezeTitle,
    descriptionKey: AppLocale.storeStreakFreezeDescription,
    price: 150,
    grants: InventoryKind.streakFreeze,
    quantity: 1,
    maxOwned: 3,
  ),
  hintPack(
    icon: Icons.lightbulb_rounded,
    titleKey: AppLocale.storeHintPackTitle,
    descriptionKey: AppLocale.storeHintPackDescription,
    price: 60,
    grants: InventoryKind.hint,
    quantity: 3,
  ),
  livesRefill(
    icon: Icons.favorite_rounded,
    titleKey: AppLocale.storeLivesRefillTitle,
    descriptionKey: AppLocale.storeLivesRefillDescription,
    price: 80,
  );

  const StoreItem({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.price,
    this.grants,
    this.quantity = 1,
    this.maxOwned,
  });

  final IconData icon;
  final String titleKey;
  final String descriptionKey;

  /// Coins it costs.
  final int price;

  /// The inventory entry it adds to, or null when it acts at once.
  final InventoryKind? grants;

  /// How many of [grants] one purchase adds.
  final int quantity;

  /// Most of [grants] the player may hold, or null for no limit.
  final int? maxOwned;
}

/// Why a purchase went through or not.
enum PurchaseResult { purchased, notEnoughCoins, limitReached, notNeeded }
