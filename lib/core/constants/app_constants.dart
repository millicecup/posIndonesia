// lib/core/constants/app_constants.dart
// Konstanta global aplikasi (PIC: Matilda).

class AppConstants {
  AppConstants._();

  static const String appName = 'JejakPOS';
  static const String tagline = 'Explore, Discover, Collect';

  // Path aset
  static const String poiDatasetPath = 'assets/data/pois.json';
  static const String museumMapImage = 'assets/map/denah_museum.jpg';
  static const String onboardingImage = 'assets/images/onboarding.png';

  // Ukuran gambar denah asli Denah2D_Real (dipakai untuk konversi mapPosition 0-1 ke koordinat peta)
  static const double mapImageWidth = 1737;
  static const double mapImageHeight = 2413;

  // Minimal jumlah POI di dataset (F03, F06)
  static const int minimumPoiCount = 10;

  // Format kode beacon dan QR
  static final RegExp beaconIdPattern = RegExp(r'^BCN-P\d{2}$');
  static final RegExp qrCodePattern = RegExp(r'^QR-P\d{2}$');

  // Key shared_preferences
  static const String prefVisitedIds = 'jejakpos.visited_poi_ids';
  static const String prefStampIds = 'jejakpos.collected_stamp_ids';
  static const String prefLastVisitedAt = 'jejakpos.last_visited_at';
  static const String prefOnboardingSeen = 'jejakpos.onboarding_seen';
  // Sesi kunjungan: POI yang sudah terpicu (reset saat "Akhiri kunjungan").
  static const String prefSessionTriggeredIds = 'jejakpos.session_triggered_ids';
  // Sesi kunjungan: sambutan "masuk area museum" sudah ditampilkan (DF-01).
  static const String prefSessionMuseumWelcomed =
      'jejakpos.session_museum_welcomed';
  // Statistik ringkasan kunjungan (UI22) dan cap kunjungan digital (A06).
  static const String prefQuizCompleted = 'jejakpos.quiz_completed';
  static const String prefPhotoCount = 'jejakpos.photo_count';
  static const String prefPostmarks = 'jejakpos.postmarks';
  // Riwayat ringkasan tiap kunjungan (JSON) + angka kumulatif di akhir kunjungan terakhir.
  static const String prefVisitHistory = 'jejakpos.visit_history';
  static const String prefVisitBaseline = 'jejakpos.visit_baseline';
  // Seed desain perangko digital acak P11 (tetap sama setelah diambil).
  static const String prefRandomStampSeed = 'jejakpos.random_stamp_seed';
  // Pemandu suara otomatis nyala/mati (default nyala).
  static const String prefVoiceGuideEnabled = 'jejakpos.voice_guide_enabled';

  // Tag log untuk bukti PB02 / trigger
  static const String logTagLocation = 'LOKASI';
  static const String logTagTrigger = 'TRIGGER';
  static const String logTagData = 'DATA';
  static const String logTagQr = 'QR';
  static const String logTagBeacon = 'BEACON';
  static const String logTagMedia = 'MEDIA';
  static const String logTagVision = 'VISION';
}
