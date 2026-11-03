// test/data/poi_repository_test.dart
// Uji search, QR/beacon lookup, kategori, nearby, rekomendasi, validasi dataset.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/data/repositories/poi_repository_impl.dart';

import '../helpers/test_data.dart';

void main() {
  late PoiRepositoryImpl repo;

  setUp(() => repo = buildRepository());

  group('searchPois', () {
    test('case-insensitive berdasarkan nama', () async {
      final result = await repo.searchPois('PRANGKO');
      expect(result.map((p) => p.id), containsAll(['P07', 'P09']));
    });

    test('berdasarkan kategori', () async {
      final result = await repo.searchPois('koleksi museum');
      expect(result.map((p) => p.id).toSet(), {'P03', 'P11'});
    });

    test('query kosong mengembalikan semua POI', () async {
      expect((await repo.searchPois('  ')).length, 13);
    });

    test('tidak ada hasil', () async {
      expect(await repo.searchPois('dinosaurus'), isEmpty);
    });
  });

  group('getPoiByBeaconOrQr', () {
    test('QR valid (huruf kecil & spasi) -> POI benar', () async {
      final poi = await repo.getPoiByBeaconOrQr('  qr-p05 ');
      expect(poi?.id, 'P05');
    });

    test('beacon valid -> POI benar', () async {
      final poi = await repo.getPoiByBeaconOrQr('BCN-P10');
      expect(poi?.id, 'P10');
    });

    test('kode tidak terdaftar -> null', () async {
      expect(await repo.getPoiByBeaconOrQr('QR-P99'), isNull);
    });
  });

  test('getCategories tanpa duplikasi', () async {
    final cats = await repo.getCategories();
    expect(cats.length, cats.map((c) => c.id).toSet().length);
    expect(cats.map((c) => c.id), contains('koleksi_museum'));
  });

  test('filterByCategory', () async {
    final result = await repo.filterByCategory(
        const PoiCategory(id: 'koleksi_museum', label: 'Koleksi Museum'));
    expect(result.map((p) => p.id), ['P03', 'P11']);
  });

  test('getPoiById', () async {
    expect((await repo.getPoiById('p04'))?.name, contains('Kepemimpinan'));
    expect(await repo.getPoiById('X'), isNull);
  });

  test('getNearbyPois urut dari yang terdekat', () async {
    final p01 = (await repo.getPoiById('P01'))!;
    final nearby = await repo.getNearbyPois(p01.latitude!, p01.longitude!, 30);
    expect(nearby.first.poi.id, 'P01');
    expect(nearby.first.distanceMeters, lessThan(0.5));
    for (var i = 1; i < nearby.length; i++) {
      expect(nearby[i].distanceMeters,
          greaterThanOrEqualTo(nearby[i - 1].distanceMeters));
    }
  });

  group('getRecommendedNextPoi', () {
    test('belum ada kunjungan -> POI urutan pertama', () async {
      expect((await repo.getRecommendedNextPoi([]))?.id, 'P01');
    });

    test('tidak merekomendasikan POI yang sudah dikunjungi', () async {
      final next = await repo.getRecommendedNextPoi(['P01']);
      expect(next, isNotNull);
      expect(next!.id, isNot('P01'));
    });

    test('semua dikunjungi -> null', () async {
      final all = (await repo.getAllPois()).map((p) => p.id).toList();
      expect(await repo.getRecommendedNextPoi(all), isNull);
    });
  });

  test('validateDataset lolos untuk dataset saat ini', () async {
    final report = await repo.validateDataset();
    expect(report.errors, isEmpty, reason: report.errors.join('\n'));
    expect(report.poiCount, greaterThanOrEqualTo(10));
    expect(report.warnings, isNotEmpty); // placeholder ditandai
  });

  test('validateDataset mendeteksi id duplikat & POI < 10', () async {
    final raw = '[${_minimalPoi('P01')}, ${_minimalPoi('P01')}]';
    final report = await buildRepository(raw).validateDataset();
    expect(report.isValid, isFalse);
    expect(report.errors.any((e) => e.contains('duplikat')), isTrue);
    expect(report.errors.any((e) => e.contains('minimal')), isTrue);
  });
}

String _minimalPoi(String id) => '''
{
  "id": "$id", "tourOrder": 1, "name": "Uji",
  "category": {"id": "uji", "label": "Uji"},
  "zone": {"code": "$id", "description": "Uji"},
  "beaconId": "BCN-$id", "qrCode": "QR-$id",
  "shortDescription": "Uji", "keyFacts": ["a", "b", "c"],
  "images": ["assets/images/pois/p01_1.png"], "audio": null,
  "contentTypes": ["text"],
  "triggerRule": {"triggerRadiusMeters": 10, "triggerOncePerSession": true},
  "systemResponse": "Uji",
  "stamp": {"id": "STP-$id", "title": "Uji", "trivia": "Uji"},
  "mapPosition": {"x": 0.5, "y": 0.5},
  "latitude": null, "longitude": null, "activity": "none"
}''';
