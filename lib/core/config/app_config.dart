// lib/core/config/app_config.dart
// Konfigurasi yang bisa diubah tanpa menyentuh logika (PIC: Matilda).

class AppConfig {
  const AppConfig({
    this.defaultTriggerRadiusMeters = 10,
    this.defaultApproachRadiusMeters = 15,
    this.hysteresisMeters = 3,
    this.requiredConsecutiveReadings = 2,
    this.maxAcceptedAccuracyMeters = 50,
    this.museumCenterLatitude = -6.90245,
    this.museumCenterLongitude = 107.61975,
    this.museumGeofenceRadiusMeters = 150,
    this.beaconRssiThreshold = -75,
    this.simulationModeDefault = false,
    this.simulationTickInterval = const Duration(seconds: 1),
    this.mediaBaseUrl = '',
  });

  /// Radius trigger default. PRD tabel POI = 5 m, Sprint 2/wireframe = 10 m.
  /// Dipakai 10 m -> PERLU KONFIRMASI tim/museum.
  final double defaultTriggerRadiusMeters;

  /// Radius status "approaching" (mendekati).
  final double defaultApproachRadiusMeters;

  /// Jarak tambahan sebelum status turun (mencegah status berkedip).
  final double hysteresisMeters;

  /// Jumlah pembacaan berturut-turut sebelum status berubah (debounce).
  final int requiredConsecutiveReadings;

  /// Pembacaan GPS dengan akurasi lebih buruk dari ini diabaikan.
  final double maxAcceptedAccuracyMeters;

  /// Titik pusat museum. PLACEHOLDER: sekitar Museum Pos Indonesia, Bandung.
  /// Koordinat asli belum tersedia.
  final double museumCenterLatitude;
  final double museumCenterLongitude;
  final double museumGeofenceRadiusMeters;

  /// Ambang RSSI beacon dianggap "dekat" (PoC PB05, perlu kalibrasi di perangkat fisik).
  final int beaconRssiThreshold;

  /// Mode simulasi aktif saat start. Bisa dipaksa lewat
  /// `flutter run --dart-define=SIMULATION=true`.
  final bool simulationModeDefault;
  final Duration simulationTickInterval;

  /// Alamat Firebase Hosting untuk audio & foto POI. Kosong = hanya aset APK.
  /// Diisi lewat `--dart-define=MEDIA_BASE_URL=https://<project-id>.web.app`.
  final String mediaBaseUrl;

  /// Konfigurasi default membaca flag --dart-define.
  factory AppConfig.fromEnvironment() {
    const sim = bool.fromEnvironment('SIMULATION', defaultValue: false);
    const mediaUrl = String.fromEnvironment('MEDIA_BASE_URL');
    return const AppConfig(simulationModeDefault: sim, mediaBaseUrl: mediaUrl);
  }
}
