// lib/features/voice_guide/state/narration_script.dart
// Naskah pemandu suara: gabungan "kamu sekarang di mana" + cerita POI dari pois.json
// (konten tervalidasi PB06) + rekomendasi berikutnya. Tidak ada fakta yang dikarang di sini.

import '../../../data/models/models.dart';

class Narration {
  const Narration({required this.title, required this.parts});

  /// Judul singkat untuk ditampilkan di bar pemandu suara.
  final String title;
  final List<String> parts;
}

class NarrationScript {
  NarrationScript._();

  /// Membersihkan penanda teknis agar enak didengar.
  static String _clean(String s) => s
      .replaceAll(RegExp(r'\[[^\]]*\]\s*'),
          '') // [PERLU VALIDASI MUSEUM], [KANDIDAT ...]
      .replaceAll(RegExp(r'^Tahap \d+ - '), '')
      .replaceAll('Rp', 'Rupiah ')
      .trim();

  static String _where(Poi poi) {
    final d = poi.zone.description;
    return d.isEmpty ? '' : ', ${d[0].toLowerCase()}${d.substring(1)}';
  }

  /// State 2: pengunjung mendekati POI.
  static Narration approaching(Poi poi) => Narration(
        title: 'Mendekati ${poi.name}',
        parts: [
          'Kamu sedang mendekati ${poi.name}${_where(poi)}. Terus berjalan, ya.'
        ],
      );

  /// State 3-4: pengunjung tiba di POI. Lokasi, ringkasan, fakta penting, aktivitas, lalu
  /// rekomendasi berikutnya.
  static Narration arrival(Poi poi, {Poi? next}) {
    final parts = <String>[
      'Sekarang kamu berada di ${poi.name}${_where(poi)}.',
    ];
    if (poi.contentValidated || poi.contentSource != null) {
      parts.add(_clean(poi.shortDescription));
      final facts =
          poi.keyFacts.take(3).map(_clean).where((f) => f.isNotEmpty).toList();
      if (facts.isNotEmpty) {
        parts.add('Beberapa hal menarik di sini. ${facts.join(' ')}');
      }
    } else {
      parts.add(
          'Informasi lengkap koleksi ini sedang disiapkan bersama museum.');
    }
    if (poi.activities.contains(PoiActivity.photoStudio)) {
      parts.add(
          'Di ruang ini kamu juga bisa berfoto dengan seragam petugas pos di studio foto.');
    }
    if (poi.id == 'P10' && poi.hasAudio) {
      parts.add('Tekan tombol putar untuk mendengarkan Mars Pos Indonesia.');
    }
    parts.add('Jangan lupa ambil perangkonya setelah selesai menjelajah.');
    if (next != null) {
      parts
          .add('Setelah ini, kamu bisa lanjut ke ${next.name}${_where(next)}.');
    }
    return Narration(title: 'Kamu di ${poi.name}', parts: parts);
  }

  /// Narasi lengkap POI (tombol "Dengar"): lokasi + seluruh cerita per bagian.
  static Narration full(Poi poi) {
    final parts = <String>['Kamu sedang di ${poi.name}${_where(poi)}.'];
    if (poi.sections.isNotEmpty) {
      for (final s in poi.sections) {
        parts.add('${s.title}.');
        parts.addAll(s.paragraphs.map(_clean));
      }
    } else {
      parts.add(_clean(poi.shortDescription));
      parts.addAll(poi.keyFacts.map(_clean));
    }
    return Narration(
        title: 'Cerita ${poi.name}',
        parts: parts.where((p) => p.isNotEmpty).toList());
  }
}
