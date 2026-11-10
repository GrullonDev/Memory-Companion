import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:memory_companion/features/ads/controller/ad_controller.dart';
import 'package:memory_companion/features/ads/model/ads_config.dart';
import 'package:memory_companion/features/ads/model/remove_ads_state.dart';

final inAppPurchaseProvider = Provider<InAppPurchase>(
  (ref) => InAppPurchase.instance,
);

/// La compra "Sin anuncios" (`remove_ads`, no consumible).
///
/// Escucha el flujo de compras de la tienda desde el arranque, como piden
/// Google Play y App Store: una compra que quedó pendiente, o que se aprobó
/// con la app cerrada, llega por ahí. Cuando una compra o una restauración
/// de `remove_ads` se confirma, se guarda en la base local y [AdController]
/// deja de cargar anuncios.
class RemoveAdsController extends AsyncNotifier<RemoveAdsState> {
  static const Duration _restoreGrace = Duration(milliseconds: 500);

  /// Llegó una compra o restauración de `remove_ads` en esta sesión.
  bool _sawRemoveAds = false;

  @override
  Future<RemoveAdsState> build() async {
    ref.keepAlive();
    if (!ref.watch(adsPlatformSupportedProvider)) {
      return const RemoveAdsState.unavailable();
    }

    final store = ref.watch(inAppPurchaseProvider);
    final subscription = store.purchaseStream.listen(
      _onPurchasesUpdated,
      onError: (Object error) => debugPrint('Purchase stream error: $error'),
    );
    ref.onDispose(subscription.cancel);

    if ((await ref.read(adsRepositoryProvider).read()).adsRemoved) {
      return const RemoveAdsState.purchased();
    }
    return _loadProduct(store);
  }

  Future<void> buy() async {
    final current = state.value;
    final product = current?.product;
    if (current == null || product == null || current.busy) return;

    state = AsyncData(current.copyWith(busy: true, clearMessage: true));
    try {
      final started = await ref
          .read(inAppPurchaseProvider)
          .buyNonConsumable(
            purchaseParam: PurchaseParam(productDetails: product),
          );
      if (!started) _finishWith(RemoveAdsMessage.purchaseFailed);
    } catch (error) {
      debugPrint('Purchase failed to start: $error');
      _finishWith(RemoveAdsMessage.purchaseFailed);
    }
  }

  /// Pide a la tienda las compras ya hechas. Si `remove_ads` está entre
  /// ellas llega por el flujo de compras como `restored`.
  Future<void> restore() async {
    final current = state.value;
    if (current == null || current.busy) return;

    state = AsyncData(current.copyWith(busy: true, clearMessage: true));
    try {
      await ref.read(inAppPurchaseProvider).restorePurchases();
    } catch (error) {
      debugPrint('Restore failed: $error');
      _finishWith(RemoveAdsMessage.restoreFailed);
      return;
    }
    // Las tiendas emiten lo restaurado antes de que termine la llamada,
    // pero el flujo lo entrega un instante después. Pasado ese margen, si no
    // apareció `remove_ads` es que no había nada que restaurar.
    await Future<void>.delayed(_restoreGrace);
    if (!_sawRemoveAds && state.value?.isPurchased != true) {
      _finishWith(RemoveAdsMessage.nothingToRestore);
    }
  }

  Future<void> _onPurchasesUpdated(List<PurchaseDetails> purchases) async {
    final store = ref.read(inAppPurchaseProvider);
    for (final purchase in purchases) {
      if (purchase.productID == AdsConfig.removeAdsProductId) {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            final current = state.value;
            if (current != null) {
              state = AsyncData(current.copyWith(busy: true));
            }
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            _sawRemoveAds = true;
            await ref.read(adsRepositoryProvider).setAdsRemoved(true);
            if (ref.mounted) {
              state = const AsyncData(
                RemoveAdsState.purchased(message: RemoveAdsMessage.thanks),
              );
            }
          case PurchaseStatus.error:
            debugPrint('Purchase error: ${purchase.error}');
            _finishWith(RemoveAdsMessage.purchaseFailed);
          case PurchaseStatus.canceled:
            _finishWith(null);
        }
      }
      // Sin esto, Google Play reembolsa la compra a los tres días y la
      // App Store la vuelve a entregar en cada arranque.
      if (purchase.pendingCompletePurchase) {
        await store.completePurchase(purchase);
      }
    }
  }

  /// Vuelve a dejar el botón disponible, con [message] si hay que decir algo.
  void _finishWith(RemoveAdsMessage? message) {
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null || current.isPurchased) return;
    state = AsyncData(
      current.copyWith(busy: false, message: message, clearMessage: true),
    );
  }

  Future<RemoveAdsState> _loadProduct(InAppPurchase store) async {
    if (!await store.isAvailable()) return const RemoveAdsState.unavailable();
    final response = await store.queryProductDetails({
      AdsConfig.removeAdsProductId,
    });
    for (final product in response.productDetails) {
      if (product.id == AdsConfig.removeAdsProductId) {
        return RemoveAdsState.available(product);
      }
    }
    debugPrint('Product ${AdsConfig.removeAdsProductId} not found in store');
    return const RemoveAdsState.unavailable();
  }
}

final removeAdsControllerProvider =
    AsyncNotifierProvider<RemoveAdsController, RemoveAdsState>(
      RemoveAdsController.new,
    );
