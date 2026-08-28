import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/features/shop/controller/shop_controller.dart';
import 'package:memory_companion/features/shop/model/plan.dart';

/// Snapshot of the player's lives: how many are left, the cap, and how
/// long until the next one recharges (0 once full or unlimited).
class LivesState {
  const LivesState({
    required this.current,
    required this.max,
    required this.secondsUntilNextLife,
  });

  final int current;
  final int max;
  final int secondsUntilNextLife;

  bool get isEmpty => current <= 0;
  bool get isFull => current >= max;

  LivesState copyWith({int? current, int? secondsUntilNextLife}) {
    return LivesState(
      current: current ?? this.current,
      max: max,
      secondsUntilNextLife: secondsUntilNextLife ?? this.secondsUntilNextLife,
    );
  }
}

/// Local lives economy for the solo board: starting a match (or retrying
/// one) costs a life, lost lives recharge one at a time on a timer, and a
/// Pro plan subscriber ([ShopController]) gets unlimited lives instead.
class LivesController extends Notifier<LivesState> {
  static const int maxLives = 5;
  static const int refillSeconds = 20 * 60;

  Timer? _timer;

  @override
  LivesState build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    return const LivesState(
      current: maxLives,
      max: maxLives,
      secondsUntilNextLife: 0,
    );
  }

  bool get hasInfiniteLives =>
      ref.read(shopControllerProvider).value?.currentPlanId == PlanId.pro;

  void _tick() {
    if (hasInfiniteLives || state.isFull) return;
    if (state.secondsUntilNextLife <= 1) {
      final next = state.current + 1;
      state = state.copyWith(
        current: next,
        secondsUntilNextLife: next >= state.max ? 0 : refillSeconds,
      );
    } else {
      state = state.copyWith(
        secondsUntilNextLife: state.secondsUntilNextLife - 1,
      );
    }
  }

  /// Spends one life to start or retry a match. Returns false — without
  /// spending anything — when the player is out of lives and not Pro.
  bool consumeLife() {
    if (hasInfiniteLives) return true;
    if (state.isEmpty) return false;
    state = state.copyWith(
      current: state.current - 1,
      secondsUntilNextLife: state.secondsUntilNextLife == 0
          ? refillSeconds
          : state.secondsUntilNextLife,
    );
    return true;
  }
}

final livesControllerProvider = NotifierProvider<LivesController, LivesState>(
  LivesController.new,
);
