import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/player/repository/player_repository.dart';

/// El saldo de monedas del jugador, compartido por Home, Tienda, Amigos,
/// Versus y el mapa de niveles.
///
/// Antes esto mutaba únicamente el estado de Riverpod: `spend()` bajaba el
/// número en pantalla y el siguiente snapshot de Firestore lo devolvía a su
/// sitio. Comprar en la tienda no descontaba nada, nunca.
///
/// Ahora el saldo **se deriva del perfil local** y las operaciones escriben en
/// SQLite. No hay ningún `state =` aquí: el stream de la base es quien
/// actualiza el estado, así que la UI y el disco no pueden desincronizarse.
class WalletController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    final player = await ref.watch(localPlayerProvider.future);
    return player.totalCoins;
  }

  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  String? get _localId => ref.read(localPlayerProvider).value?.localId;

  /// Gasta [amount]. Devuelve `false` si el saldo no alcanza, sin tocar nada.
  Future<bool> spend(int amount) async {
    final localId = _localId;
    if (localId == null) return false;
    return _repository.spendCoins(localId: localId, amount: amount);
  }

  /// Suma [amount] al saldo.
  Future<void> add(int amount) async {
    final localId = _localId;
    if (localId == null) return;
    await _repository.earnCoins(localId: localId, amount: amount);
  }
}

final walletControllerProvider = AsyncNotifierProvider<WalletController, int>(
  WalletController.new,
);
