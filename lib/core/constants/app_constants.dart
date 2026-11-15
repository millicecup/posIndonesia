// lib/core/constants/app_constants.dart
// Konstanta global aplikasi (PIC: Matilda).

class AppConstants {
  AppConstants._();

  static const String appName = 'JejakPOS';
  static const String tagline = 'Explore, Discover, Collect';

  // Path aset
  static const String poiDatasetPath = 'assets/data/pois.json';
  static const String museumMapImage = 'assets/map/Denah2D_Real.jpg';
  static const String onboardingImage = 'assets/images/onboarding.png';

  // Ukuran gambar denah (dipakai untuk konversi mapPosition 0-1 ke koordinat peta)
  static const double mapImageWidth = 1000;
  static const double mapImageHeight = 700;

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

  // Tag log untuk bukti PB02 / trigger
  static const String logTagLocation = 'LOKASI';
  static const String logTagTrigger = 'TRIGGER';
  static const String logTagData = 'DATA';
  static const String logTagQr = 'QR';
  static const String logTagBeacon = 'BEACON';
}
