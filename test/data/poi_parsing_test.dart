// test/data/poi_parsing_test.dart
// Uji parsing JSON dataset POI.

import 'dart:convert';
import 'dart:io';

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

    test('PRD v2 Tabel 4: P01-P11 baseline, P12-P13 kandidat tambahan', () {
      final pois = loadDataset();
      final baseline = pois.where((p) => p.isBaseline).map((p) => p.id).toList();
      expect(baseline, [for (var i = 1; i <= 11; i++) 'P${i.toString().padLeft(2, '0')}']);
      expect(pois.where((p) => !p.isBaseline).map((p) => p.id), ['P12', 'P13']);
      for (final p in pois) {
        expect(p.tourOrder, int.parse(p.id.substring(1)), reason: p.id);
        expect(p.zone.code, p.id);
        expect(p.stamp.id, 'STP-${p.id}');
      }
    });

    test('nama POI sesuai urutan PRD v2 Tabel 4', () {
      final names = {for (final p in loadDataset()) p.id: p.name};
      expect(names['P03'], contains('Kepemimpinan'));
      expect(names['P04'], contains('Seragam'));
      expect(names['P05'], contains('Pembuatan Prangko'));
      expect(names['P06'], contains('Kode Pos'));
      expect(names['P07'], contains('Lemari Geser'));
      expect(names['P08'], contains('Mas Soeharto'));
      expect(names['P09'], contains('Kotak Pos'));
      expect(names['P10'], contains('Mars Pos'));
      expect(names['P11'], contains('Stempel'));
      expect(names['P12'], contains('Peralatan Pos'));
      expect(names['P13'], contains('Kereta Api'));
    });

    test('field wajib terisi dan format kode konsisten', () {
      for (final p in loadDataset()) {
        expect(p.beaconId, 'BCN-${p.id}');
        expect(p.qrCode, 'QR-${p.id}');
        expect(p.keyFacts.length, inInclusiveRange(3, 5));
        expect(p.images, isNotEmpty);
        expect(p.mapPosition.isValid, isTrue);
        expect(p.triggerRule.triggerRadiusMeters, 10);
      }
    });

    test('sesuai PRD v2 Tabel 4: P10 audio, P04 Photo Studio, P05 lima tahap', () {
      final pois = loadDataset();
      Poi byId(String id) => pois.firstWhere((p) => p.id == id);
      expect(byId('P10').contentTypes, contains(PoiContentType.audio));
      expect(byId('P10').hasAudio, isTrue);
      expect(byId('P04').activities, contains(PoiActivity.photoStudio));
      expect(byId('P05').keyFacts, hasLength(5));
      expect(byId('P05').activities, contains(PoiActivity.stampVisualization));
      expect(byId('P06').activities, contains(PoiActivity.minigame));
      expect(byId('P08').activities, contains(PoiActivity.mystery));
      expect(byId('P11').activities, contains(PoiActivity.postmark));
      expect(byId('P12').activities,
          containsAll([PoiActivity.gallery, PoiActivity.quiz, PoiActivity.mission]));
      expect(byId('P11').zone.description, contains('Meja Registrasi'));
    });

    test('konten content/poi-dataset: P01-P11 tervalidasi', () {
      final pois = loadDataset();
      Poi byId(String id) => pois.firstWhere((p) => p.id == id);
      for (var i = 1; i <= 11; i++) {
        final p = byId('P${i.toString().padLeft(2, '0')}');
        expect(p.contentValidated, isTrue, reason: p.id);
        expect(p.sections, isNotEmpty, reason: p.id);
        expect(p.shortDescription, isNot(contains('PERLU VALIDASI')), reason: p.id);
        expect(p.keyFacts.join(), isNot(contains('PERLU VALIDASI')), reason: p.id);
        expect(p.images.first, endsWith('.jpg'), reason: p.id);
      }
      // P12-P13 kandidat tambahan (backlog), belum ada materi.
      for (final id in ['P12', 'P13']) {
        expect(byId(id).contentValidated, isFalse, reason: id);
      }
      expect(byId('P04').sections.map((s) => s.title),
          ['Seragam Petugas Pos', 'Topi, Lencana, dan Tas']);
      expect(byId('P02').curatedQuiz, hasLength(5));
      expect(byId('P06').sections.map((s) => s.body).join(),
          isNot(contains('nanti aku tambahin')));
    });

    test('semua gambar (termasuk gambar per bagian cerita) ada di assets', () {
      for (final p in loadDataset()) {
        for (final path in p.mediaPaths) {
          expect(File(path).existsSync(), isTrue, reason: '${p.id}: $path');
        }
      }
    });

    test('soal tervalidasi: jawaban sesuai materi', () {
      final pois = loadDataset();
      final p08 = pois.firstWhere((p) => p.id == 'P08');
      expect(p08.mysteryClues, hasLength(3));
      expect(p08.curatedQuiz.map((q) => q.options[q.answerIndex]),
          ['Semarang', 'Boedi Oetomo', 'R. Dijar dan para pemuda PTT']);
      final p06 = pois.firstWhere((p) => p.id == 'P06');
      final q1 = p06.curatedQuiz.first;
      expect(q1.question, contains('angka 1'));
      expect(q1.options[q1.answerIndex], 'Jakarta dan sekitarnya');
    });

    test('F03: minimal 10 POI baseline punya narasi audio', () {
      final withAudio =
          loadDataset().where((p) => p.isBaseline && p.hasAudio).length;
      expect(withAudio, greaterThanOrEqualTo(10));
    });

    test('audio dan activities boleh kosong', () {
      final pois = loadDataset();
      final p09 = pois.firstWhere((p) => p.id == 'P09');
      expect(p09.audio, isNull);
      expect(p09.hasAudio, isFalse);
      expect(pois.firstWhere((p) => p.id == 'P10').activities, isEmpty);
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
