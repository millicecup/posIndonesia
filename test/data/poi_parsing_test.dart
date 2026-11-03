// test/data/poi_parsing_test.dart
// Uji parsing JSON dataset POI.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/core/errors/app_exception.dart';
import 'package:jejakpos/core/utils/haversine.dart';
import 'package:jejakpos/data/datasources/poi_local_datasource.dart';
import 'package:jejakpos/data/models/models.dart';

import '../helpers/test_data.dart';

void main() {
  group('Parsing pois.json', () {
    test('memuat 13 POI dengan id P01-P13 berurutan', () {
      final pois = loadDataset();
      expect(pois.length, 13);
      expect(pois.first.id, 'P01');
      expect(pois.last.id, 'P13');
    });

    test('field wajib terisi dan format kode konsisten', () {
      for (final p in loadDataset()) {
        expect(p.beaconId, 'BCN-${p.id}');
        expect(p.qrCode, 'QR-${p.id}');
        expect(p.keyFacts.length, inInclusiveRange(3, 5));
        expect(p.images, isNotEmpty);
        expect(p.mapPosition.isValid, isTrue);
        expect(p.triggerRule.triggerRadiusMeters, 10);
        expect(p.contentValidated, isFalse);
      }
    });

    test('sesuai PRD Tabel 4: P05 audio, P06 Photo Studio, P07 lima tahap', () {
      final pois = loadDataset();
      Poi byId(String id) => pois.firstWhere((p) => p.id == id);
      expect(byId('P05').contentTypes, contains(PoiContentType.audio));
      expect(byId('P05').hasAudio, isTrue);
      expect(byId('P06').activities, contains(PoiActivity.photoStudio));
      expect(byId('P07').keyFacts, hasLength(5));
      expect(byId('P07').activities, contains(PoiActivity.stampVisualization));
      expect(byId('P03').activities,
          containsAll([PoiActivity.gallery, PoiActivity.quiz, PoiActivity.mission]));
      expect(byId('P12').zone.description, contains('pintu masuk'));
    });

    test('F03: minimal 10 POI punya narasi audio', () {
      final withAudio = loadDataset().where((p) => p.hasAudio).length;
      expect(withAudio, greaterThanOrEqualTo(10));
    });

    test('audio dan activities boleh kosong', () {
      final pois = loadDataset();
      final p11 = pois.firstWhere((p) => p.id == 'P11');
      expect(p11.audio, isNull);
      expect(p11.hasAudio, isFalse);
      expect(pois.firstWhere((p) => p.id == 'P02').activities, isEmpty);
    });

    test('jarak antar-POI (placeholder) > 20 m agar radius 10 m tidak tumpang tindih', () {
      final pois = loadDataset();
      for (var i = 0; i < pois.length; i++) {
        for (var j = i + 1; j < pois.length; j++) {
          final d = haversineDistanceMeters(pois[i].latitude!, pois[i].longitude!,
              pois[j].latitude!, pois[j].longitude!);
          expect(d, greaterThan(20), reason: '${pois[i].id}-${pois[j].id}');
        }
      }
    });

    test('toJson -> fromJson menghasilkan data yang sama', () {
      final original = loadDataset().first;
      final copy = Poi.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>);
      expect(copy, original);
      expect(copy.name, original.name);
      expect(copy.keyFacts, original.keyFacts);
      expect(copy.triggerRule, original.triggerRule);
      expect(copy.stamp, original.stamp);
    });

    test('copyWith hanya mengubah field yang diberikan', () {
      final p = loadDataset().first;
      final changed = p.copyWith(name: 'Baru');
      expect(changed.name, 'Baru');
      expect(changed.id, p.id);
      expect(changed.keyFacts, p.keyFacts);
    });

    test('JSON rusak melempar DataParseException', () {
      expect(() => PoiLocalDataSource.parsePois('{bukan json'),
          throwsA(isA<DataParseException>()));
    });

    test('field wajib hilang melempar DataParseException', () {
      final json = jsonDecode(readDatasetJson()) as Map<String, dynamic>;
      final first = Map<String, dynamic>.from((json['pois'] as List).first as Map);
      first.remove('name');
      expect(() => PoiLocalDataSource.parsePois(jsonEncode([first])),
          throwsA(isA<DataParseException>()));
    });
  });
}
