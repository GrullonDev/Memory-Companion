import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart' as ble_out;
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble_in;

import 'package:memory_companion/features/game_context/service/nearby_beacon.dart';

/// Finds other Memory Arcade players in Bluetooth range, and lets them find
/// this one.
///
/// Both halves are needed: `flutter_blue_plus` only scans (it cannot put
/// the phone on air), so advertising goes through `flutter_ble_peripheral`.
abstract interface class NearbyRadio {
  /// Asks for the Bluetooth permissions if they have not been answered yet.
  /// True when the app may both scan and advertise.
  Future<bool> requestPermission();

  /// Starts broadcasting [friendCode], replacing any earlier broadcast.
  Future<void> startAdvertising(String friendCode);

  Future<void> stopAdvertising();

  /// Friend codes heard during [duration], or null when the radio could not
  /// listen at all (Bluetooth off, unsupported, no permission). An empty set
  /// means it listened and nobody was there.
  Future<Set<String>?> scan(Duration duration);
}

/// [NearbyRadio] over the real Bluetooth stack.
class BleNearbyRadio implements NearbyRadio {
  BleNearbyRadio();

  final _peripheral = ble_out.FlutterBlePeripheral();
  String? _advertising;

  @override
  Future<bool> requestPermission() async {
    try {
      if (!await ble_in.FlutterBluePlus.isSupported) return false;
      if (!await _peripheral.isSupported) return false;
      var state = await _peripheral.hasPermission();
      if (!_allowed(state)) state = await _peripheral.requestPermission();
      return _allowed(state);
    } catch (e) {
      debugPrint('Bluetooth permission failed: $e');
      return false;
    }
  }

  @override
  Future<void> startAdvertising(String friendCode) async {
    if (_advertising == friendCode) return;
    try {
      if (_advertising != null) await _peripheral.stop();
      await _peripheral.start(
        advertiseData: ble_out.AdvertiseDataCore(
          serviceUuid: NearbyBeacon.uuidFor(friendCode),
        ),
      );
      _advertising = friendCode;
    } catch (e) {
      _advertising = null;
      debugPrint('Bluetooth advertising failed: $e');
    }
  }

  @override
  Future<void> stopAdvertising() async {
    if (_advertising == null) return;
    _advertising = null;
    try {
      await _peripheral.stop();
    } catch (e) {
      debugPrint('Bluetooth stop failed: $e');
    }
  }

  @override
  Future<Set<String>?> scan(Duration duration) async {
    try {
      if (!await ble_in.FlutterBluePlus.isSupported) return null;
      final adapter = await ble_in.FlutterBluePlus.adapterState
          .firstWhere((s) => s != ble_in.BluetoothAdapterState.unknown)
          .timeout(const Duration(seconds: 2));
      if (adapter != ble_in.BluetoothAdapterState.on) return null;

      final codes = <String>{};
      final subscription = ble_in.FlutterBluePlus.onScanResults.listen((
        results,
      ) {
        for (final result in results) {
          for (final uuid in result.advertisementData.serviceUuids) {
            final code = NearbyBeacon.codeFrom(uuid.str128);
            if (code != null) codes.add(code);
          }
        }
      });
      try {
        await ble_in.FlutterBluePlus.startScan(timeout: duration);
        await ble_in.FlutterBluePlus.isScanning
            .firstWhere((on) => !on)
            .timeout(duration + const Duration(seconds: 3));
      } finally {
        await subscription.cancel();
      }
      return codes;
    } catch (e) {
      debugPrint('Bluetooth scan failed: $e');
      return null;
    }
  }

  static bool _allowed(ble_out.PeripheralBluetoothState state) =>
      state == ble_out.PeripheralBluetoothState.granted ||
      state == ble_out.PeripheralBluetoothState.ready ||
      // Allowed, only switched off: scanning will say so when it runs.
      state == ble_out.PeripheralBluetoothState.turnedOff;
}
