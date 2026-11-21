// test/features/narration_script_test.dart
// Naskah pemandu suara: menyebut lokasi, memakai konten tervalidasi, tanpa penanda teknis.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/features/voice_guide/state/narration_script.dart';

import '../helpers/test_data.dart';

void main() {
  final pois = loadDataset();
  final byId = {for (final p in pois) p.id: p};

  test('narasi kedatangan menyebut lokasi, ringkasan, dan rekomendasi berikutnya', () {
    final n = NarrationScript.arrival(byId['P04']!, next: byId['P06']);
    final text = n.parts.join(' ');
    expect(n.parts.first, startsWith('Sekarang kamu berada di Sejarah Seragam Petugas Pos'));
    expect(text, contains(byId['P04']!.shortDescription));
    expect(text, contains('studio foto'));
    expect(n.parts.last, contains('Kode Pos di Indonesia'));
  });

  test('narasi mendekati menyebut nama POI', () {
    expect(NarrationScript.approaching(byId['P01']!).parts.single,
        contains('mendekati Sejarah Komunikasi Tertulis di Nusantara'));
  });

  test('cerita lengkap membacakan semua bagian', () {
    final n = NarrationScript.full(byId['P07']!);
    for (final s in byId['P07']!.sections) {
      expect(n.parts, contains('${s.title}.'));
    }
  });

  test('tidak ada penanda teknis yang ikut dibacakan', () {
    for (final p in pois.where((p) => p.isBaseline)) {
      final text = [
        ...NarrationScript.arrival(p).parts,
        ...NarrationScript.full(p).parts,
      ].join(' ');
      expect(text, isNot(contains('[')), reason: p.id);
      expect(text, isNot(contains('PERLU VALIDASI')), reason: p.id);
    }
  });

  test('audio placeholder ditandai; Mars P10 rekaman asli', () {
    expect(byId['P10']!.hasRealAudio, isTrue);
    expect(byId['P01']!.hasRealAudio, isFalse);
    expect(byId['P01']!.audioPlaceholder, isTrue);
  });
}
