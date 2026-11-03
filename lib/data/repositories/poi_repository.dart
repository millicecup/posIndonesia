// lib/data/repositories/poi_repository.dart
// Kontrak akses data POI. Frontend hanya bergantung pada abstract class ini.

import '../models/poi.dart';
import '../models/poi_category.dart';

/// Hasil getNearbyPois: POI + jaraknya dari pengguna.
typedef NearbyPoi = ({Poi poi, double distanceMeters});

/// Laporan validasi dataset (bukti PB03).
class DatasetValidationReport {
  const DatasetValidationReport({
    required this.poiCount,
    required this.errors,
    required this.warnings,
  });

  final int poiCount;
  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;

  @override
  String toString() =>
      'Validasi dataset: $poiCount POI, ${errors.length} error, ${warnings.length} peringatan';
}

abstract class PoiRepository {
  Future<List<Poi>> getAllPois();

  Future<Poi?> getPoiById(String id);

  /// Cari POI dari kode beacon ("BCN-P01") atau QR ("QR-P01").
  Future<Poi?> getPoiByBeaconOrQr(String code);

  /// Pencarian case-insensitive berdasarkan nama atau kategori.
  Future<List<Poi>> searchPois(String query);

  Future<List<Poi>> filterByCategory(PoiCategory category);

  Future<List<PoiCategory>> getCategories();

  /// POI yang punya koordinat dan berada dalam [radiusMeters], urut terdekat.
  Future<List<NearbyPoi>> getNearbyPois(
      double latitude, double longitude, double radiusMeters);

  /// Rekomendasi POI berikutnya yang belum dikunjungi. null jika semua selesai.
  Future<Poi?> getRecommendedNextPoi(List<String> visitedIds);

  Future<DatasetValidationReport> validateDataset();
}
