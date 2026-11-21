// lib/services/permission_service.dart
// Cek & minta izin lokasi, kamera, notifikasi (PIC backend: Matilda, UI: Firda).

import 'package:permission_handler/permission_handler.dart';

import '../core/utils/app_logger.dart';

/// Sesuai PRD UI02: Bluetooth & Lokasi, Kamera, Notifikasi.
enum AppPermissionType { location, bluetooth, camera, notification }

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited
}

extension AppPermissionTypeX on AppPermissionType {
  String get label {
    switch (this) {
      case AppPermissionType.location:
        return 'Lokasi';
      case AppPermissionType.bluetooth:
        return 'Bluetooth';
      case AppPermissionType.camera:
        return 'Kamera';
      case AppPermissionType.notification:
        return 'Notifikasi';
    }
  }
}

extension AppPermissionStatusX on AppPermissionStatus {
  String get label {
    switch (this) {
      case AppPermissionStatus.granted:
        return 'Diizinkan';
      case AppPermissionStatus.denied:
        return 'Ditolak';
      case AppPermissionStatus.permanentlyDenied:
        return 'Ditolak permanen';
      case AppPermissionStatus.restricted:
        return 'Dibatasi sistem';
      case AppPermissionStatus.limited:
        return 'Terbatas';
    }
  }

  bool get isGranted =>
      this == AppPermissionStatus.granted ||
      this == AppPermissionStatus.limited;
}

class PermissionService {
  static const requiredPermissions = [
    AppPermissionType.location,
    AppPermissionType.camera,
    AppPermissionType.notification
  ];
  static const _tag = 'IZIN';

  Permission _map(AppPermissionType type) {
    switch (type) {
      case AppPermissionType.location:
        return Permission.locationWhenInUse;
      case AppPermissionType.bluetooth:
        // Android 12+: BLUETOOTH_SCAN. Di emulator tidak ada BLE, tapi izin tetap bisa diberikan.
        return Permission.bluetoothScan;
      case AppPermissionType.camera:
        return Permission.camera;
      case AppPermissionType.notification:
        return Permission.notification;
    }
  }

  AppPermissionStatus _convert(PermissionStatus status) {
    if (status.isGranted) return AppPermissionStatus.granted;
    if (status.isLimited) return AppPermissionStatus.limited;
    if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return AppPermissionStatus.restricted;
    return AppPermissionStatus.denied;
  }

  Future<AppPermissionStatus> check(AppPermissionType type) async {
    final status = await _map(type).status;
    return _convert(status);
  }

  Future<AppPermissionStatus> request(AppPermissionType type) async {
    final status = await _map(type).request();
    final result = _convert(status);
    AppLogger.info(_tag, 'Minta izin ${type.label}: ${result.label}');
    return result;
  }

  Future<Map<AppPermissionType, AppPermissionStatus>> checkAll() async {
    final result = <AppPermissionType, AppPermissionStatus>{};
    for (final type in requiredPermissions) {
      result[type] = await check(type);
    }
    return result;
  }

  /// Buka halaman pengaturan aplikasi (untuk izin ditolak permanen).
  Future<bool> openSettings() => openAppSettings();
}
