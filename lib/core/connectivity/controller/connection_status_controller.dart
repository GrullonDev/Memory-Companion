import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device currently has a usable network connection.
enum ConnectionStatus { online, offline }

/// Tracks the device's connectivity by listening to [Connectivity] and
/// exposing a simple [ConnectionStatus], so any screen can watch it to
/// warn the player their progress will sync once the network is back.
class ConnectionStatusController extends Notifier<ConnectionStatus> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectionStatus build() {
    final connectivity = Connectivity();

    connectivity.checkConnectivity().then((results) {
      state = _statusFromResults(results);
    });

    _subscription = connectivity.onConnectivityChanged.listen((results) {
      state = _statusFromResults(results);
    });
    ref.onDispose(() => _subscription?.cancel());

    return ConnectionStatus.online;
  }

  ConnectionStatus _statusFromResults(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );
    return hasConnection ? ConnectionStatus.online : ConnectionStatus.offline;
  }
}

final connectionStatusControllerProvider =
    NotifierProvider<ConnectionStatusController, ConnectionStatus>(
      ConnectionStatusController.new,
    );
