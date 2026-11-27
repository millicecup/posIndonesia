// lib/core/config/app_config.dart
// Konfigurasi yang bisa diubah tanpa menyentuh logika (PIC: Matilda).

class AppConfig {
  const AppConfig({
    this.defaultTriggerRadiusMeters = 3,
    this.defaultApproachRadiusMeters = 6,
    this.hysteresisMeters = 1,
    this.gpsTriggerMaxAccuracyMeters = 5,
    this.requiredConsecutiveReadings = 2,
    this.maxAcceptedAccuracyMeters = 50,
    this.museumCenterLatitude = -6.902572,
    this.museumCenterLongitude = 107.620269,
    this.museumGeofenceRadiusMeters = 150,
    this.beaconRssiThreshold = -75,
    this.simulationModeDefault = false,
    this.simulationTickInterval = const Duration(seconds: 1),
    this.mediaBaseUrl = '',
    this.visionMinSimilarity = 0.5,
    this.visionMinMargin = 0.05,
    this.visionRequiredFrames = 3,
    this.visionFrameInterval = const Duration(milliseconds: 500),
    this.visionGpsSlackMeters = 8,
    this.visionGpsPenaltyPerMeter = 0.01,
    this.visionGpsMaxPenalty = 0.15,
    this.visionNoMatchHintFrames = 6,
  });

  /// Radius trigger default. Koordinat asli (Koordinat POI.pdf) menunjukkan
  /// jarak antar-POI hanya 1-10 m, jadi radius diperkecil dari 10 m ke 3 m.
  /// Pengenal utama saat tur adalah computer vision (lihat vision*), GPS hanya pendukung.
  final double defaultTriggerRadiusMeters;

  /// Radius status "approaching" (mendekati).
  final double defaultApproachRadiusMeters;

  /// Jarak tambahan sebelum status turun (mencegah status berkedip).
  final double hysteresisMeters;

  /// GPS asli hanya boleh MEMICU POI jika akurasinya <= nilai ini. Di dalam
  /// gedung akurasi biasanya 5-20 m, jadi GPS cukup memberi status "mendekati"
  /// dan konfirmasi POI diserahkan ke computer vision / QR / beacon.
  final double gpsTriggerMaxAccuracyMeters;

  /// Jumlah pembacaan berturut-turut sebelum status berubah (debounce).
  final int requiredConsecutiveReadings;

  /// Pembacaan GPS dengan akurasi lebih buruk dari ini diabaikan.
  final double maxAcceptedAccuracyMeters;

  /// Titik pusat museum: rata-rata koordinat P01-P11 dari "Koordinat POI.pdf".
  /// Semua POI baseline berada <= 21 m dari titik ini.
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

  // ---- Computer vision (pengenalan pameran lewat kamera) ----

  /// Cosine similarity minimal frame kamera vs foto referensi POI.
  final double visionMinSimilarity;

  /// Selisih skor minimal POI teratas vs POI kedua (hindari tebakan ragu-ragu).
  final double visionMinMargin;

  /// Jumlah frame berturut-turut dengan POI teratas yang sama sebelum dikonfirmasi.
  final int visionRequiredFrames;

  /// Jeda antar-frame yang dianalisis (hemat baterai).
  final Duration visionFrameInterval;

  /// Penggabungan dengan GPS: POI yang lebih jauh dari (akurasi GPS + slack)
  /// diberi penalti skor per meter, maksimal [visionGpsMaxPenalty].
  /// Penalti (bukan filter keras) agar GPS yang meleset tidak menghapus POI yang benar.
  final double visionGpsSlackMeters;
  final double visionGpsPenaltyPerMeter;
  final double visionGpsMaxPenalty;

  /// Setelah sekian frame berturut-turut tanpa POI yang dikenali, layar Kenali
  /// memberi tahu bahwa objek mungkin bukan koleksi POI dan menawarkan QR /
  /// koleksi lain (DF-02). 6 frame x jeda 0,5 dtk + waktu analisis = sekitar 4-6 dtk.
  final int visionNoMatchHintFrames;

  /// Konfigurasi default membaca flag --dart-define.
  factory AppConfig.fromEnvironment() {
    const sim = bool.fromEnvironment('SIMULATION', defaultValue: false);
    const mediaUrl = String.fromEnvironment('MEDIA_BASE_URL');
    return const AppConfig(simulationModeDefault: sim, mediaBaseUrl: mediaUrl);
  }
}
