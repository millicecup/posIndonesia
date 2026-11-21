// lib/data/repositories/poi_repository_impl.dart
// Implementasi PoiRepository berbasis JSON lokal + cache memori (PIC: Matilda).

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/haversine.dart';
import '../datasources/poi_local_datasource.dart';
import '../models/poi.dart';
import '../models/poi_category.dart';
import 'poi_repository.dart';

/// Fungsi pengecek keberadaan aset (bisa diganti saat unit test).
typedef AssetExistsChecker = Future<bool> Function(String path);

class PoiRepositoryImpl implements PoiRepository {
  PoiRepositoryImpl(
    this._dataSource, {
    AssetExistsChecker? assetExists,
    this.remoteMediaEnabled = false,
    this.includeBacklog = false,
  }) : _assetExists = assetExists ?? _defaultAssetExists;

  final PoiLocalDataSource _dataSource;
  final AssetExistsChecker _assetExists;

  /// true = audio & foto POI boleh tidak ada di APK karena diunduh dari Hosting.
  final bool remoteMediaEnabled;

  /// false (default) = POI kandidat/backlog (baseline=false, mis. P12-P13) tidak
  /// ditampilkan di aplikasi dan tidak bisa terpicu. Datanya tetap ada di pois.json.
  final bool includeBacklog;

  List<Poi>? _cache;
  Future<List<Poi>>? _loading;

  static Future<bool> _defaultAssetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Kosongkan cache (misal setelah dataset diganti).
  void invalidateCache() {
    _cache = null;
    _loading = null;
  }

  @override
  Future<List<Poi>> getAllPois() async {
    final all = await getAllPoisIncludingBacklog();
    if (includeBacklog) return all;
    return List.unmodifiable(all.where((p) => p.isBaseline));
  }

  /// Seluruh isi dataset, termasuk POI kandidat/backlog (untuk validasi).
  Future<List<Poi>> getAllPoisIncludingBacklog() async {
    final cached = _cache;
    if (cached != null) return cached;
    // Hindari load ganda jika dipanggil bersamaan.
    _loading ??= _dataSource.loadPois();
    try {
      final pois = await _loading!;
      _cache = pois;
      return pois;
    } catch (_) {
      _loading = null;
      rethrow;
    }
  }

  @override
  Future<Poi?> getPoiById(String id) async {
    final pois = await getAllPois();
    final key = id.trim().toUpperCase();
    for (final p in pois) {
      if (p.id.toUpperCase() == key) return p;
    }
    return null;
  }

  @override
  Future<Poi?> getPoiByBeaconOrQr(String code) async {
    final key = code.trim().toUpperCase();
    if (key.isEmpty) return null;
    final pois = await getAllPois();
    for (final p in pois) {
      if (p.qrCode.toUpperCase() == key || p.beaconId.toUpperCase() == key) {
        return p;
      }
    }
    return null;
  }

  @override
  Future<List<Poi>> searchPois(String query) async {
    final pois = await getAllPois();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return pois;
    return pois
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.category.label.toLowerCase().contains(q) ||
            p.category.id.toLowerCase().contains(q) ||
            p.id.toLowerCase() == q)
        .toList(growable: false);
  }

  @override
  Future<List<Poi>> filterByCategory(PoiCategory category) async {
    final pois = await getAllPois();
    return pois.where((p) => p.category == category).toList(growable: false);
  }

  @override
  Future<List<PoiCategory>> getCategories() async {
    final pois = await getAllPois();
    final seen = <String>{};
    final result = <PoiCategory>[];
    for (final p in pois) {
      if (seen.add(p.category.id)) result.add(p.category);
    }
    return List.unmodifiable(result);
  }

  @override
  Future<List<NearbyPoi>> getNearbyPois(
      double latitude, double longitude, double radiusMeters) async {
    final pois = await getAllPois();
    final result = <NearbyPoi>[];
    for (final p in pois) {
      if (!p.hasCoordinates) continue;
      final d = haversineDistanceMeters(
          latitude, longitude, p.latitude!, p.longitude!);
      if (d <= radiusMeters) result.add((poi: p, distanceMeters: d));
    }
    result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return result;
  }

  @override
  Future<Poi?> getRecommendedNextPoi(List<String> visitedIds) async {
    final pois = await getAllPois();
    final visited = visitedIds.map((e) => e.toUpperCase()).toSet();
    final remaining =
        pois.where((p) => !visited.contains(p.id.toUpperCase())).toList();
    if (remaining.isEmpty) return null;

    // Belum ada kunjungan -> mulai dari urutan tur pertama.
    if (visitedIds.isEmpty) return remaining.first;

    // Ada kunjungan -> pilih yang terdekat di denah dari POI terakhir.
    final last = await getPoiById(visitedIds.last);
    if (last == null) return remaining.first;
    remaining.sort((a, b) {
      final da = a.mapPosition.distanceTo(last.mapPosition);
      final db = b.mapPosition.distanceTo(last.mapPosition);
      final cmp = da.compareTo(db);
      return cmp != 0 ? cmp : a.tourOrder.compareTo(b.tourOrder);
    });
    return remaining.first;
  }

  @override
  Future<DatasetValidationReport> validateDataset() async {
    final errors = <String>[];
    final warnings = <String>[];
    List<Poi> pois;
    try {
      pois = await getAllPoisIncludingBacklog();
    } catch (e) {
      return DatasetValidationReport(
          poiCount: 0,
          errors: ['Dataset gagal dimuat: $e'],
          warnings: const []);
    }

    if (pois.length < AppConstants.minimumPoiCount) {
      errors.add(
          'Jumlah POI ${pois.length}, minimal ${AppConstants.minimumPoiCount}');
    }
    // G08/F03: minimal 10 POI baseline (PRD v2 Tabel 4), kandidat tambahan tidak dihitung.
    final baselineCount = pois.where((p) => p.isBaseline).length;
    if (baselineCount < AppConstants.minimumPoiCount) {
      errors.add('Jumlah POI baseline $baselineCount, '
          'minimal ${AppConstants.minimumPoiCount}');
    }

    final ids = <String>{};
    final beacons = <String>{};
    final qrs = <String>{};
    final stamps = <String>{};

    for (final p in pois) {
      final tag = 'POI ${p.id}';
      if (!ids.add(p.id)) errors.add('$tag: id duplikat');
      if (!beacons.add(p.beaconId)) errors.add('$tag: beaconId duplikat');
      if (!qrs.add(p.qrCode)) errors.add('$tag: qrCode duplikat');
      if (!stamps.add(p.stamp.id)) errors.add('$tag: stamp.id duplikat');

      if (p.name.trim().isEmpty) errors.add('$tag: name kosong');
      if (p.shortDescription.trim().isEmpty) {
        errors.add('$tag: shortDescription kosong');
      }
      if (p.systemResponse.trim().isEmpty) {
        errors.add('$tag: systemResponse kosong');
      }
      if (p.keyFacts.length > 5) {
        errors.add('$tag: keyFacts maksimal 5 (sekarang ${p.keyFacts.length})');
      }
      if (p.images.isEmpty) errors.add('$tag: images kosong');
      if (p.contentTypes.isEmpty) errors.add('$tag: contentTypes kosong');
      if (!AppConstants.beaconIdPattern.hasMatch(p.beaconId)) {
        errors.add('$tag: format beaconId "${p.beaconId}" salah (BCN-Pxx)');
      }
      if (!AppConstants.qrCodePattern.hasMatch(p.qrCode)) {
        errors.add('$tag: format qrCode "${p.qrCode}" salah (QR-Pxx)');
      }
      if (!p.mapPosition.isValid) errors.add('$tag: mapPosition di luar 0-1');
      if (p.triggerRule.triggerRadiusMeters <= 0) {
        errors.add('$tag: triggerRadiusMeters harus > 0');
      }
      if (p.triggerRule.approachRadiusMeters <
          p.triggerRule.triggerRadiusMeters) {
        errors.add('$tag: approachRadiusMeters < triggerRadiusMeters');
      }

      // Path aset harus ada di bundle.
      final assetPaths = <String>[
        if (!remoteMediaEnabled) ...p.mediaPaths,
        if (p.stamp.image != null) p.stamp.image!,
      ];
      for (final path in assetPaths) {
        if (!await _assetExists(path))
          errors.add('$tag: aset "$path" tidak ditemukan');
      }

      // Peringatan (bukan error) untuk hal yang belum pasti.
      if (!p.hasAudio) warnings.add('$tag: belum ada audio');
      if (!p.hasCoordinates) warnings.add('$tag: belum ada koordinat');
      if (p.coordinatesArePlaceholder) {
        warnings.add('$tag: koordinat masih PLACEHOLDER');
      }
      if (!p.contentValidated)
        warnings.add('$tag: konten PERLU VALIDASI MUSEUM');
      if (!p.isBaseline) {
        warnings
            .add('$tag: kandidat tambahan, tidak ada di PRD v2 Tabel 4 (NG08)');
      }
      if (p.triggerRule.radiusNeedsConfirmation) {
        warnings.add(
            '$tag: radius trigger perlu konfirmasi (PRD v2 PB08: 5 m, kode: 10 m)');
      }
    }

    // poiCount = POI yang tampil di aplikasi (baseline), kandidat dicatat di warnings.
    final report = DatasetValidationReport(
        poiCount: includeBacklog ? pois.length : baselineCount,
        errors: errors,
        warnings: warnings);
    AppLogger.info(AppConstants.logTagData, report.toString());
    for (final e in errors) {
      AppLogger.error(AppConstants.logTagData, e);
    }
    return report;
  }
}
