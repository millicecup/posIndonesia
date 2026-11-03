// lib/services/trigger_engine.dart
// Geofencing + logika trigger POI sekali per sesi (F02). Pure Dart -> mudah di-test.
//
// Alur: posisi -> jarak Haversine ke tiap POI -> status (outside/approaching/triggered)
//       -> hysteresis + debounce -> TriggerEvent (stream) -> UI.

import 'dart:async';
import 'dart:math' as math;

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/haversine.dart';
import '../data/models/location_status.dart';
import '../data/models/poi.dart';

enum PoiProximity { outside, approaching, triggered }

enum TriggerEventType { approaching, triggered, exited }

/// Dari mana POI terdeteksi (hybrid trigger).
enum TriggerSource { gps, simulation, beacon, qr }

class TriggerEvent {
  const TriggerEvent({
    required this.poi,
    required this.type,
    required this.source,
    required this.timestamp,
    this.distanceMeters,
  });

  final Poi poi;
  final TriggerEventType type;
  final TriggerSource source;
  final DateTime timestamp;
  final double? distanceMeters;

  @override
  String toString() =>
      'TriggerEvent(${poi.id}, ${type.name}, ${source.name}'
      '${distanceMeters != null ? ', ${distanceMeters!.toStringAsFixed(1)} m' : ''})';
}

/// Status terkini satu POI (untuk peta/daftar).
class PoiProximityStatus {
  const PoiProximityStatus({
    required this.poiId,
    required this.proximity,
    this.distanceMeters,
  });

  final String poiId;
  final PoiProximity proximity;
  final double? distanceMeters;
}

class _PoiState {
  PoiProximity proximity = PoiProximity.outside;
  PoiProximity? pending;
  int pendingCount = 0;
  double? distance;
}

class TriggerEngine {
  TriggerEngine({this.config = const AppConfig()});

  final AppConfig config;
  static const _tag = AppConstants.logTagTrigger;

  final _eventController = StreamController<TriggerEvent>.broadcast();
  final _statusController =
      StreamController<Map<String, PoiProximityStatus>>.broadcast();

  List<Poi> _pois = const [];
  final Map<String, _PoiState> _states = {};
  final Set<String> _triggeredThisSession = {};
  bool _insideMuseum = false;
  bool _disposed = false;

  /// Event trigger untuk dikonsumsi UI.
  Stream<TriggerEvent> get events => _eventController.stream;

  /// Status semua POI setiap kali posisi diperbarui.
  Stream<Map<String, PoiProximityStatus>> get statusStream =>
      _statusController.stream;

  bool get isInsideMuseum => _insideMuseum;
  Set<String> get triggeredThisSession => Set.unmodifiable(_triggeredThisSession);
  bool hasTriggered(String poiId) => _triggeredThisSession.contains(poiId);

  Map<String, PoiProximityStatus> get statuses => {
        for (final e in _states.entries)
          e.key: PoiProximityStatus(
            poiId: e.key,
            proximity: e.value.proximity,
            distanceMeters: e.value.distance,
          ),
      };

  /// Daftarkan POI yang dipantau.
  void setPois(List<Poi> pois) {
    _pois = List.unmodifiable(pois);
    _states.removeWhere((id, _) => !pois.any((p) => p.id == id));
    for (final p in pois) {
      _states.putIfAbsent(p.id, _PoiState.new);
    }
    AppLogger.info(_tag, 'TriggerEngine memantau ${pois.length} POI');
  }

  /// Proses posisi baru. Mengembalikan event yang dihasilkan (juga dikirim ke stream).
  List<TriggerEvent> updatePosition(UserPosition position) {
    if (_disposed) return const [];
    if (position.accuracyMeters > config.maxAcceptedAccuracyMeters) {
      AppLogger.warning(_tag,
          'Posisi diabaikan, akurasi ${position.accuracyMeters.toStringAsFixed(0)} m terlalu buruk');
      return const [];
    }

    _updateMuseumGeofence(position);

    final source = position.source == PositionSource.simulation
        ? TriggerSource.simulation
        : TriggerSource.gps;
    final events = <TriggerEvent>[];

    for (final poi in _pois) {
      if (!poi.hasCoordinates) continue;
      final state = _states.putIfAbsent(poi.id, _PoiState.new);
      final d = haversineDistanceMeters(
          position.latitude, position.longitude, poi.latitude!, poi.longitude!);
      state.distance = d;

      final candidate = _candidateProximity(d, state.proximity, poi);
      if (candidate == state.proximity) {
        state.pending = null;
        state.pendingCount = 0;
        continue;
      }

      // Debounce: status baru harus terbaca N kali berturut-turut.
      if (state.pending == candidate) {
        state.pendingCount++;
      } else {
        state.pending = candidate;
        state.pendingCount = 1;
      }
      if (state.pendingCount < config.requiredConsecutiveReadings) continue;

      final previous = state.proximity;
      state.proximity = candidate;
      state.pending = null;
      state.pendingCount = 0;

      final event = _onTransition(poi, previous, candidate, source, d);
      if (event != null) events.add(event);
    }

    for (final e in events) {
      _emit(e);
    }
    if (!_statusController.isClosed) _statusController.add(statuses);
    return events;
  }

  /// POI teridentifikasi langsung lewat beacon/QR (bukan jarak GPS).
  TriggerEvent? reportIdentification(Poi poi, TriggerSource source) {
    if (_disposed) return null;
    final state = _states.putIfAbsent(poi.id, _PoiState.new);
    if (poi.triggerRule.triggerOncePerSession &&
        _triggeredThisSession.contains(poi.id)) {
      AppLogger.info(_tag,
          '${poi.id} terdeteksi via ${source.name}, tapi sudah terpicu sesi ini (diabaikan)');
      return null;
    }
    state.proximity = PoiProximity.triggered;
    _triggeredThisSession.add(poi.id);
    final event = TriggerEvent(
      poi: poi,
      type: TriggerEventType.triggered,
      source: source,
      timestamp: DateTime.now(),
    );
    _emit(event);
    return event;
  }

  /// Pulihkan POI yang sudah terpicu pada kunjungan yang sama
  /// (misal aplikasi ditutup lalu dibuka lagi sebelum "Akhiri kunjungan").
  void restoreSession(Iterable<String> triggeredPoiIds) {
    _triggeredThisSession.addAll(triggeredPoiIds);
    if (_triggeredThisSession.isNotEmpty) {
      AppLogger.info(_tag, 'Sesi dipulihkan, sudah terpicu: ${_triggeredThisSession.join(', ')}');
    }
  }

  /// Mulai sesi kunjungan baru (semua POI bisa terpicu lagi).
  void resetSession() {
    _triggeredThisSession.clear();
    for (final s in _states.values) {
      s
        ..proximity = PoiProximity.outside
        ..pending = null
        ..pendingCount = 0
        ..distance = null;
    }
    AppLogger.info(_tag, 'Sesi trigger direset');
  }

  void dispose() {
    _disposed = true;
    _eventController.close();
    _statusController.close();
  }

  // ---------------- internal ----------------

  /// Status kandidat dengan hysteresis: batas keluar lebih longgar dari batas masuk.
  PoiProximity _candidateProximity(double d, PoiProximity current, Poi poi) {
    final trigger = poi.triggerRule.triggerRadiusMeters;
    final approach = math.max(poi.triggerRule.approachRadiusMeters, trigger);
    final h = config.hysteresisMeters;

    switch (current) {
      case PoiProximity.triggered:
        if (d <= trigger + h) return PoiProximity.triggered;
        if (d <= approach + h) return PoiProximity.approaching;
        return PoiProximity.outside;
      case PoiProximity.approaching:
        if (d <= trigger) return PoiProximity.triggered;
        if (d <= approach + h) return PoiProximity.approaching;
        return PoiProximity.outside;
      case PoiProximity.outside:
        if (d <= trigger) return PoiProximity.triggered;
        if (d <= approach) return PoiProximity.approaching;
        return PoiProximity.outside;
    }
  }

  TriggerEvent? _onTransition(Poi poi, PoiProximity from, PoiProximity to,
      TriggerSource source, double distance) {
    TriggerEvent make(TriggerEventType type) => TriggerEvent(
          poi: poi,
          type: type,
          source: source,
          timestamp: DateTime.now(),
          distanceMeters: distance,
        );

    switch (to) {
      case PoiProximity.triggered:
        if (_triggeredThisSession.contains(poi.id)) {
          AppLogger.info(
              _tag, '${poi.id} dimasuki lagi, sudah terpicu sesi ini (tidak diulang)');
          return null;
        }
        _triggeredThisSession.add(poi.id);
        return make(TriggerEventType.triggered);
      case PoiProximity.approaching:
        if (from == PoiProximity.outside) {
          return make(TriggerEventType.approaching);
        }
        return null;
      case PoiProximity.outside:
        // Jika boleh terpicu ulang, aktifkan kembali setelah benar-benar keluar.
        if (!poi.triggerRule.triggerOncePerSession) {
          _triggeredThisSession.remove(poi.id);
        }
        return make(TriggerEventType.exited);
    }
  }

  void _updateMuseumGeofence(UserPosition p) {
    final d = haversineDistanceMeters(p.latitude, p.longitude,
        config.museumCenterLatitude, config.museumCenterLongitude);
    final inside = d <= config.museumGeofenceRadiusMeters;
    if (inside != _insideMuseum) {
      _insideMuseum = inside;
      AppLogger.info(
          _tag,
          inside
              ? 'Masuk area museum (${d.toStringAsFixed(0)} m dari pusat)'
              : 'Keluar area museum (${d.toStringAsFixed(0)} m dari pusat)');
    }
  }

  void _emit(TriggerEvent e) {
    AppLogger.info(_tag, e.toString());
    if (!_eventController.isClosed) _eventController.add(e);
  }
}
