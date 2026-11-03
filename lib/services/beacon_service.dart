// lib/services/beacon_service.dart
// Antarmuka pemindai BLE beacon. Sprint 1: hanya kontrak + implementasi simulasi.
// Implementasi asli (flutter_blue_plus) dikerjakan Firda di branch PoC PB05,
// diuji hanya di perangkat fisik (emulator tidak punya BLE).

import 'dart:async';

/// Satu sinyal beacon yang terbaca.
class BeaconSignal {
  const BeaconSignal({
    required this.beaconId,
    required this.rssi,
    required this.timestamp,
  });

  /// Format sama dengan dataset, misal "BCN-P01".
  final String beaconId;

  /// Kekuatan sinyal (dBm). Makin mendekati 0 makin dekat.
  final int rssi;
  final DateTime timestamp;

  @override
  String toString() => 'BeaconSignal($beaconId, $rssi dBm)';
}

abstract class BeaconScanner {
  bool get isSupported;
  Stream<BeaconSignal> get signals;
  Future<void> start();
  Future<void> stop();
}

/// Placeholder pemindai BLE asli. Jangan dipakai di emulator.
/// TODO(Firda, PB05): implementasi dengan flutter_blue_plus:
///   1. Aktifkan dependency flutter_blue_plus di pubspec.yaml.
///   2. FlutterBluePlus.startScan(timeout: ...)
///   3. Petakan ScanResult (nama/UUID/major-minor) -> beaconId "BCN-Pxx".
///   4. Kirim BeaconSignal ke stream [signals].
class UnsupportedBeaconScanner implements BeaconScanner {
  final _controller = StreamController<BeaconSignal>.broadcast();

  @override
  bool get isSupported => false;

  @override
  Stream<BeaconSignal> get signals => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
