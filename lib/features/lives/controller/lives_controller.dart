import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:memory_companion/core/database/database_provider.dart';
import 'package:memory_companion/features/lives/model/lives_recovery.dart';
import 'package:memory_companion/features/lives/repository/lives_repository.dart';
import 'package:memory_companion/features/player/controller/player_controller.dart';
import 'package:memory_companion/features/shop/controller/shop_controller.dart';
import 'package:memory_companion/features/shop/model/plan.dart';

/// Instantánea de las vidas del jugador.
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
}

final livesRepositoryProvider = Provider<LivesRepository>((ref) {
  return LivesRepository(database: ref.watch(appDatabaseProvider));
});

/// Economía de vidas, ahora persistida.
///
/// Antes vivía solo en memoria: cerrar y reabrir la app devolvía las cinco
/// vidas, así que el límite era evitable sin querer, y el temporizador de
/// recarga solo avanzaba con la app abierta. Ahora se guardan las vidas y el
/// instante en que empezó la recarga, y al arrancar se deduce del reloj
/// cuántas se han recuperado mientras tanto.
class LivesController extends AsyncNotifier<LivesState> {
  static const int maxLives = 5;
  static const Duration refillInterval = Duration(minutes: 20);

  Timer? _timer;
  late String _playerLocalId;
  late int _storedLives;
  late DateTime _storedLastRefillAt;

  @override
  Future<LivesState> build() async {
    ref.keepAlive();
    ref.onDispose(() => _timer?.cancel());

    final player = await ref.watch(localPlayerProvider.future);
    _playerLocalId = player.localId;

    final row = await ref.read(livesRepositoryProvider).ensure(
          playerLocalId: _playerLocalId,
          initialLives: maxLives,
          now: DateTime.now(),
        );
    _storedLives = row.currentLives;
    _storedLastRefillAt =
        DateTime.fromMillisecondsSinceEpoch(row.lastRefillAt);

    final snapshot = await _applyRecovery();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    return snapshot;
  }

  bool get hasInfiniteLives =>
      ref.read(shopControllerProvider).value?.currentPlanId == PlanId.pro;

  /// Recalcula desde el reloj y persiste si se ha recuperado alguna vida.
  Future<LivesState> _applyRecovery() async {
    final snapshot = recoverLives(
      storedCurrent: _storedLives,
      storedLastRefillAt: _storedLastRefillAt,
      now: DateTime.now(),
      maxLives: maxLives,
      refillInterval: refillInterval,
    );

    if (snapshot.current != _storedLives) {
      _storedLives = snapshot.current;
      _storedLastRefillAt = snapshot.lastRefillAt;
      await ref.read(livesRepositoryProvider).save(
            playerLocalId: _playerLocalId,
            currentLives: _storedLives,
            lastRefillAt: _storedLastRefillAt,
          );
    }

    return LivesState(
      current: snapshot.current,
      max: maxLives,
      secondsUntilNextLife: snapshot.secondsUntilNextLife,
    );
  }

  Future<void> _tick() async {
    if (hasInfiniteLives || _storedLives >= maxLives) return;
    state = AsyncData(await _applyRecovery());
  }

  /// Gasta una vida para empezar o reintentar una partida.
  ///
  /// Devuelve `false` —sin gastar nada— cuando no quedan vidas y el jugador
  /// no tiene plan Pro.
  Future<bool> consumeLife() async {
    if (hasInfiniteLives) return true;
    if (_storedLives <= 0) return false;

    // Gastar desde el máximo es lo que arranca el reloj de recarga.
    final wasFull = _storedLives >= maxLives;
    _storedLives -= 1;
    if (wasFull) _storedLastRefillAt = DateTime.now();

    await ref.read(livesRepositoryProvider).save(
          playerLocalId: _playerLocalId,
          currentLives: _storedLives,
          lastRefillAt: _storedLastRefillAt,
        );

    state = AsyncData(await _applyRecovery());
    return true;
  }
}

final livesControllerProvider =
    AsyncNotifierProvider<LivesController, LivesState>(LivesController.new);
