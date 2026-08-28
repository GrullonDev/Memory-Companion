import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Owns the player's coin balance, shared by every screen that shows the
/// coin counter (Home, Friends, Shop, Versus, Level Map).
class WalletController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return 1250;
  }

  bool spend(int amount) {
    final current = state.value;
    if (current == null || current < amount) return false;
    state = AsyncValue.data(current - amount);
    return true;
  }

  void add(int amount) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current + amount);
  }
}

final walletControllerProvider = AsyncNotifierProvider<WalletController, int>(
  WalletController.new,
);
