import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:memory_companion/core/database/app_database.dart';
import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/ads/controller/ad_controller.dart';
import 'package:memory_companion/features/ads/controller/remove_ads_controller.dart';
import 'package:memory_companion/features/ads/model/ads_config.dart';
import 'package:memory_companion/features/ads/model/remove_ads_state.dart';
import 'package:memory_companion/features/ads/repository/ads_repository.dart';
import 'package:memory_companion/features/ads/service/interstitial_ad_service.dart';

class _FakeAdService implements InterstitialAdService {
  int preloads = 0;
  int shows = 0;
  bool throwOnShow = false;
  Completer<bool>? showGate;

  @override
  void preload() => preloads++;

  @override
  Future<bool> show() async {
    shows++;
    if (throwOnShow) throw StateError('ad failed');
    final gate = showGate;
    return gate == null ? true : gate.future;
  }

  @override
  void dispose() {}
}

class _FakeStore extends Fake implements InAppPurchase {
  final purchases = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  bool available = true;
  int buys = 0;
  List<PurchaseDetails> onRestore = const [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => purchases.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: AdsConfig.removeAdsProductId,
          title: 'Sin anuncios',
          description: '',
          price: r'$2.99',
          rawPrice: 2.99,
          currencyCode: 'USD',
        ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buys++;
    return true;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    if (onRestore.isNotEmpty) purchases.add(onRestore);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }
}

PurchaseDetails _removeAds(PurchaseStatus status) {
  return PurchaseDetails(
    productID: AdsConfig.removeAdsProductId,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  )..pendingCompletePurchase = true;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late AppDatabase db;
  late AdsRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AdsRepository(database: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AdsConfig', () {
    test('toca intersticial cada interstitialEveryLevels niveles', () {
      const every = AdsConfig.interstitialEveryLevels;
      expect(AdsConfig.isInterstitialDue(0), isFalse);
      expect(AdsConfig.isInterstitialDue(every - 1), isFalse);
      expect(AdsConfig.isInterstitialDue(every), isTrue);
      expect(AdsConfig.isInterstitialDue(every + 1), isFalse);
      expect(AdsConfig.isInterstitialDue(every * 2), isTrue);
    });
  });

  group('AdsRepository', () {
    test('sin fila: anuncios activos y contador a cero', () async {
      final state = await repository.read();
      expect(state.adsRemoved, isFalse);
      expect(state.levelsCompletedCount, 0);
    });

    test('cuenta niveles sin tocar la compra', () async {
      await repository.setAdsRemoved(true);
      expect(await repository.recordLevelCompleted(), 1);
      expect(await repository.recordLevelCompleted(), 2);

      final state = await repository.read();
      expect(state.adsRemoved, isTrue);
      expect(state.levelsCompletedCount, 2);
    });
  });

  group('AdController', () {
    late _FakeAdService ads;
    late ProviderContainer container;

    setUp(() {
      ads = _FakeAdService();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          adsPlatformSupportedProvider.overrideWithValue(true),
          interstitialAdServiceProvider.overrideWithValue(ads),
        ],
      );
      addTearDown(container.dispose);
    });

    Future<void> completeLevels(int count) async {
      final controller = container.read(adControllerProvider.notifier);
      for (var i = 0; i < count; i++) {
        expect(await controller.onLevelCompleted(), isTrue);
      }
    }

    test('muestra un intersticial cada N niveles', () async {
      await completeLevels(AdsConfig.interstitialEveryLevels * 2);
      expect(ads.shows, 2);
    });

    test('precarga mientras haya anuncios', () async {
      // Como en MyApp: escuchado, no solo leído (Riverpod 3 pausa lo que
      // nadie escucha).
      container.listen(adControllerProvider, (_, _) {});
      for (var i = 0; i < 50 && ads.preloads == 0; i++) {
        await _settle();
      }
      expect(ads.preloads, greaterThan(0));
    });

    test('con "Sin anuncios" no muestra ninguno', () async {
      await repository.setAdsRemoved(true);
      await completeLevels(AdsConfig.interstitialEveryLevels * 2);
      expect(ads.shows, 0);
    });

    test('un anuncio que falla no frena el juego', () async {
      ads.throwOnShow = true;
      await completeLevels(AdsConfig.interstitialEveryLevels);
      expect(ads.shows, 1);
    });

    test('sin AdMob no cuenta ni muestra nada', () async {
      final other = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          adsPlatformSupportedProvider.overrideWithValue(false),
          interstitialAdServiceProvider.overrideWithValue(ads),
        ],
      );
      addTearDown(other.dispose);

      final controller = other.read(adControllerProvider.notifier);
      expect(await controller.onLevelCompleted(), isTrue);
      expect(ads.shows, 0);
      expect((await repository.read()).levelsCompletedCount, 0);
    });

    test('un doble toque no avanza dos veces', () async {
      await completeLevels(AdsConfig.interstitialEveryLevels - 1);
      ads.showGate = Completer<bool>();
      final controller = container.read(adControllerProvider.notifier);

      final first = controller.onLevelCompleted();
      await _settle();
      expect(await controller.onLevelCompleted(), isFalse);

      ads.showGate!.complete(true);
      expect(await first, isTrue);
      expect(
        (await repository.read()).levelsCompletedCount,
        AdsConfig.interstitialEveryLevels,
      );
    });
  });

  group('RemoveAdsController', () {
    late _FakeStore store;
    late ProviderContainer container;

    setUp(() {
      store = _FakeStore();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          adsPlatformSupportedProvider.overrideWithValue(true),
          inAppPurchaseProvider.overrideWithValue(store),
          interstitialAdServiceProvider.overrideWithValue(_FakeAdService()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(store.purchases.close);
    });

    Future<RemoveAdsState> load() =>
        container.read(removeAdsControllerProvider.future);

    test('sin plataforma compatible no toca la tienda', () async {
      final other = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          adsPlatformSupportedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(other.dispose);

      final state = await other.read(removeAdsControllerProvider.future);
      expect(state.isPurchased, isFalse);
      expect(state.product, isNull);
    });

    test('ofrece el producto con el precio de la tienda', () async {
      final state = await load();
      expect(state.canBuy, isTrue);
      expect(state.product?.price, r'$2.99');
    });

    test('sin tienda no se puede comprar', () async {
      store.available = false;
      final state = await load();
      expect(state.canBuy, isFalse);
    });

    test('una compra confirmada quita los anuncios y se completa', () async {
      await load();
      await container.read(removeAdsControllerProvider.notifier).buy();
      expect(store.buys, 1);

      final purchase = _removeAds(PurchaseStatus.purchased);
      store.purchases.add([purchase]);
      await _settle();

      expect(
        container.read(removeAdsControllerProvider).value?.isPurchased,
        isTrue,
      );
      expect((await repository.read()).adsRemoved, isTrue);
      expect(store.completed, [purchase]);
    });

    test('una compra cancelada deja el botón disponible', () async {
      await load();
      await container.read(removeAdsControllerProvider.notifier).buy();
      store.purchases.add([_removeAds(PurchaseStatus.canceled)]);
      await _settle();

      final state = container.read(removeAdsControllerProvider).value!;
      expect(state.isPurchased, isFalse);
      expect(state.canBuy, isTrue);
      expect(state.message, isNull);
      expect((await repository.read()).adsRemoved, isFalse);
    });

    test('restaurar recupera la compra', () async {
      await load();
      store.onRestore = [_removeAds(PurchaseStatus.restored)];
      await container.read(removeAdsControllerProvider.notifier).restore();

      expect(
        container.read(removeAdsControllerProvider).value?.isPurchased,
        isTrue,
      );
      expect((await repository.read()).adsRemoved, isTrue);
    });

    test('restaurar sin compras lo dice', () async {
      await load();
      await container.read(removeAdsControllerProvider.notifier).restore();

      final state = container.read(removeAdsControllerProvider).value!;
      expect(state.isPurchased, isFalse);
      expect(state.message, RemoveAdsMessage.nothingToRestore);
    });

    test('ya comprado en la base: no consulta la tienda', () async {
      await repository.setAdsRemoved(true);
      final state = await load();
      expect(state.isPurchased, isTrue);
    });
  });
}
