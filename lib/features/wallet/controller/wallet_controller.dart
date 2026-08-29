import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/auth/controller/user_controller.dart';

/// Owns the player's coin balance, shared by every screen that shows the
/// coin counter (Home, Friends, Shop, Versus, Level Map).
class WalletController extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    // Fetch user data from Firestore
    final user = await ref.watch(currentUserProvider.future);

    // Return total coins from Firestore, default to 0 if no user
    return user?.totalCoins ?? 0;
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
