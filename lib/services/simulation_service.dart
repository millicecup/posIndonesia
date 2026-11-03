// lib/services/simulation_service.dart
// Lokasi & beacon palsu untuk Android Emulator (tidak ada BLE, kamera virtual).
// Aktif lewat --dart-define=SIMULATION=true atau toggle di panel debug.

import 'dart:async';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../data/models/location_status.dart';
import '../data/models/poi.dart';
import 'beacon_service.dart';

class SimulationService {
  SimulationService({this.config = const AppConfig()});

  final AppConfig config;
  static const _tag = 'SIMULASI';

  final _positionController = StreamController<UserPosition>.broadcast();
  final _beaconController = StreamController<BeaconSignal>.broadcast();
  Timer? _ticker;
  UserPosition? _current;

  UserPosition? get currentPosition => _current;

  /// Stream posisi palsu. Posisi dikirim ulang tiap tick seperti GPS asli,
  /// sehingga debounce TriggerEngine tetap terpenuhi.
  Stream<UserPosition> get positionStream => _positionController.stream;

  // ---------- Posisi ----------

  void setPosition(double latitude, double longitude, {double accuracy = 5}) {
    _current = UserPosition(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy,
      timestamp: DateTime.now(),
      source: PositionSource.simulation,
    );
    AppLogger.info(_tag, 'Posisi simulasi diset: $_current');
    _emitCurrent();
    _ensureTicker();
  }

  /// "Pindah ke POI Pxx". Jika POI tidak punya koordinat, kirim beacon palsu.
  void moveToPoi(Poi poi) {
    if (poi.hasCoordinates) {
      AppLogger.info(_tag, 'Pindah ke ${poi.id} (${poi.name})');
      setPosition(poi.latitude!, poi.longitude!);
    } else {
      emitBeacon(poi.beaconId);
    }
  }

  /// Pindah ke luar pintu masuk (±104 m selatan pusat, di luar radius semua POI,
  /// masih di dalam geofence museum). Sama dengan titik awal GPX contoh.
  void moveToMuseumEntrance() => setPosition(
      config.museumCenterLatitude - 0.00094, config.museumCenterLongitude);

  void stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    AppLogger.info(_tag, 'Simulasi posisi dihentikan');
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(config.simulationTickInterval, (_) => _emitCurrent());
  }

  void _emitCurrent() {
    final c = _current;
    if (c == null || _positionController.isClosed) return;
    _positionController.add(c.copyWith(timestamp: DateTime.now()));
  }

  // ---------- Beacon palsu (BeaconScanner) ----------

  void emitBeacon(String beaconId, {int rssi = -60}) {
    final signal = BeaconSignal(
        beaconId: beaconId.toUpperCase(), rssi: rssi, timestamp: DateTime.now());
    AppLogger.info(AppConstants.logTagBeacon, 'Beacon simulasi: $signal');
    if (!_beaconController.isClosed) _beaconController.add(signal);
  }

  Stream<BeaconSignal> get beaconSignals => _beaconController.stream;

  void dispose() {
    _ticker?.cancel();
    _positionController.close();
    _beaconController.close();
  }
}

/// Adapter: SimulationService dipakai sebagai BeaconScanner di emulator.
class SimulatedBeaconScanner implements BeaconScanner {
  SimulatedBeaconScanner(this._simulation);

  final SimulationService _simulation;

  @override
  bool get isSupported => true;

  @override
  Stream<BeaconSignal> get signals => _simulation.beaconSignals;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}
