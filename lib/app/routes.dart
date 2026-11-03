// lib/app/routes.dart
// Daftar path rute. Nomor UI mengikuti PRD Bagian 5.1 (Screen/State List).
// Pakai konstanta ini, jangan tulis string path manual.

class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding'; // UI01 Welcome / Onboarding
  static const String permission = '/permission'; // UI02 Izin Akses
  static const String explore = '/explore'; // UI03 Home / Museum Explorer (tab Jelajah)
  static const String poiList = '/pois'; // UI04 Search POI
  static const String map = '/map'; // UI05 & UI06 Explore Map state 1/2 (tab Peta)
  static String navigateTo(String poiId) => '/navigate/$poiId'; // UI07 Navigasi ke POI
  static String triggerAlert(String poiId) => '/trigger/$poiId'; // UI08 POI Trigger Notification
  static const String tour = '/tour'; // UI09 Visual Tour Guide
  static String poiDetail(String poiId) => '/poi/$poiId'; // UI10 POI Detail
  static String audioPlayer(String poiId) => '/poi/$poiId/audio'; // UI11 Audio Player
  static const String qrScanner = '/qr'; // UI12 Pindai QR (fallback)
  static const String album = '/album'; // UI14 Album Perangko Digital (tab Album)
  static const String progress = '/progress'; // UI21 Progres & Rekomendasi (tab Progres)
  static const String simulation = '/debug/simulation'; // panel emulator (bukan bagian PRD)
}
