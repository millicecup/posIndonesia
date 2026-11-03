// lib/services/location_service.dart
// Membaca GPS via geolocator + log status deteksi (bukti PB02).

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import '../data/models/location_status.dart';

class LocationService {
  static const _tag = AppConstants.logTagLocation;

  UserPosition? _lastPosition;
  UserPosition? get lastPosition => _lastPosition;

  /// Status izin + layanan lokasi saat ini.
  Future<LocationStatus> checkStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      AppLogger.warning(_tag, 'Layanan lokasi nonaktif');
      return LocationStatus.serviceDisabled;
    }
    final status = _convert(await Geolocator.checkPermission());
    AppLogger.info(_tag, 'Status izin: ${status.label}');
    return status;
  }

  /// Minta izin lokasi jika belum diberikan.
  Future<LocationStatus> requestPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return LocationStatus.serviceDisabled;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final status = _convert(permission);
    AppLogger.info(_tag, 'Hasil permintaan izin: ${status.label}');
    return status;
  }

  LocationStatus _convert(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationStatus.granted;
      case LocationPermission.deniedForever:
        return LocationStatus.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationStatus.denied;
    }
  }

  /// Ambil posisi sekali. Melempar LocationException jika tidak bisa.
  Future<UserPosition> getCurrentPosition() async {
    final status = await checkStatus();
    if (!status.isGranted) {
      throw LocationException('Tidak bisa membaca lokasi: ${status.label}');
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return _record(_fromGeolocator(p));
    } on TimeoutException catch (e) {
      throw LocationException('Lokasi tidak terbaca dalam 20 detik', cause: e);
    } catch (e) {
      throw LocationException('Gagal membaca lokasi', cause: e);
    }
  }

  /// Stream posisi saat pengguna berpindah (F01).
  Stream<UserPosition> positionStream({int distanceFilterMeters = 1}) {
    AppLogger.info(_tag, 'Mulai mendengarkan stream GPS');
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).map((p) => _record(_fromGeolocator(p)));
  }

  UserPosition _fromGeolocator(Position p) => UserPosition(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracyMeters: p.accuracy,
        timestamp: DateTime.now(),
        source: PositionSource.gps,
      );

  UserPosition _record(UserPosition position) {
    _lastPosition = position;
    AppLogger.info(_tag, 'Lokasi terbaca: $position');
    return position;
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
