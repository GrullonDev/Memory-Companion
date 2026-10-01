import 'package:in_app_purchase/in_app_purchase.dart';

/// Algo que contarle al jugador tras comprar o restaurar.
enum RemoveAdsMessage {
  thanks,
  purchaseFailed,
  restoreFailed,
  nothingToRestore,
}

/// Estado de la compra "Sin anuncios" para la UI.
class RemoveAdsState {
  const RemoveAdsState._({
    required this.isPurchased,
    this.product,
    this.busy = false,
    this.message,
  });

  /// La tienda tiene el producto y se puede comprar.
  const RemoveAdsState.available(ProductDetails product)
    : this._(isPurchased: false, product: product);

  /// Sin tienda o sin producto: no se puede comprar, pero sí intentar
  /// restaurar.
  const RemoveAdsState.unavailable() : this._(isPurchased: false);

  const RemoveAdsState.purchased({RemoveAdsMessage? message})
    : this._(isPurchased: true, message: message);

  final bool isPurchased;

  /// Con el precio ya formateado por la tienda en la moneda del jugador.
  final ProductDetails? product;

  /// Una compra o restauración en curso.
  final bool busy;
  final RemoveAdsMessage? message;

  bool get canBuy => !isPurchased && product != null && !busy;

  RemoveAdsState copyWith({
    bool? busy,
    RemoveAdsMessage? message,
    bool clearMessage = false,
  }) {
    return RemoveAdsState._(
      isPurchased: isPurchased,
      product: product,
      busy: busy ?? this.busy,
      message: message ?? (clearMessage ? null : this.message),
    );
  }
}
