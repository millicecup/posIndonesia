// lib/data/models/visit_record.dart
// Ringkasan satu kunjungan yang sudah diakhiri (UI22, A06). Disimpan permanen agar
// riwayat & ringkasan aktivitas tetap ada setelah aplikasi ditutup (DF-05).

import 'dart:convert';

/// Angka kumulatif saat sebuah kunjungan diakhiri; dipakai untuk menghitung
/// aktivitas kunjungan berikutnya (selisih).
class ActivitySnapshot {
  const ActivitySnapshot({
    this.visitedPoiIds = const [],
    this.stampIds = const [],
    this.quizCompleted = 0,
    this.photoCount = 0,
  });

  final List<String> visitedPoiIds;
  final List<String> stampIds;
  final int quizCompleted;
  final int photoCount;

  Map<String, dynamic> toJson() => {
        'visitedPoiIds': visitedPoiIds,
        'stampIds': stampIds,
        'quizCompleted': quizCompleted,
        'photoCount': photoCount,
      };

  factory ActivitySnapshot.fromJson(Map<String, dynamic> json) =>
      ActivitySnapshot(
        visitedPoiIds: _strings(json['visitedPoiIds']),
        stampIds: _strings(json['stampIds']),
        quizCompleted: _int(json['quizCompleted']),
        photoCount: _int(json['photoCount']),
      );
}

class VisitRecord {
  const VisitRecord({
    required this.endedAt,
    this.poiIds = const [],
    this.stampIds = const [],
    this.quizCompleted = 0,
    this.photoCount = 0,
    this.totalVisited = 0,
    this.totalStamps = 0,
  });

  /// Waktu "Akhiri kunjungan" ditekan (tanggal cap kunjungan).
  final DateTime endedAt;

  /// POI yang baru dikunjungi pada kunjungan ini.
  final List<String> poiIds;

  /// Prangko yang baru didapat pada kunjungan ini.
  final List<String> stampIds;
  final int quizCompleted;
  final int photoCount;

  /// Total kumulatif saat kunjungan diakhiri.
  final int totalVisited;
  final int totalStamps;

  /// Kunjungan dari versi lama (hanya tanggal cap, tanpa rincian).
  factory VisitRecord.legacy(DateTime endedAt) => VisitRecord(endedAt: endedAt);

  /// Rincian aktivitas kunjungan = selisih [current] terhadap [before].
  factory VisitRecord.between({
    required DateTime endedAt,
    required ActivitySnapshot before,
    required ActivitySnapshot current,
  }) {
    final seenPois = before.visitedPoiIds.toSet();
    final seenStamps = before.stampIds.toSet();
    int positive(int v) => v < 0 ? 0 : v;
    return VisitRecord(
      endedAt: endedAt,
      poiIds: current.visitedPoiIds.where((id) => !seenPois.contains(id)).toList(),
      stampIds: current.stampIds.where((id) => !seenStamps.contains(id)).toList(),
      quizCompleted: positive(current.quizCompleted - before.quizCompleted),
      photoCount: positive(current.photoCount - before.photoCount),
      totalVisited: current.visitedPoiIds.length,
      totalStamps: current.stampIds.length,
    );
  }

  /// Ringkasan satu baris, mis. "3 POI, 2 prangko, 1 kuis, 0 foto".
  String get activityLine => '${poiIds.length} POI, ${stampIds.length} prangko, '
      '$quizCompleted kuis, $photoCount foto';

  Map<String, dynamic> toJson() => {
        'endedAt': endedAt.toIso8601String(),
        'poiIds': poiIds,
        'stampIds': stampIds,
        'quizCompleted': quizCompleted,
        'photoCount': photoCount,
        'totalVisited': totalVisited,
        'totalStamps': totalStamps,
      };

  static VisitRecord? fromJson(Map<String, dynamic> json) {
    final ended = DateTime.tryParse('${json['endedAt']}');
    if (ended == null) return null;
    return VisitRecord(
      endedAt: ended,
      poiIds: _strings(json['poiIds']),
      stampIds: _strings(json['stampIds']),
      quizCompleted: _int(json['quizCompleted']),
      photoCount: _int(json['photoCount']),
      totalVisited: _int(json['totalVisited']),
      totalStamps: _int(json['totalStamps']),
    );
  }

  static String encodeList(List<VisitRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  /// Data rusak diabaikan (tidak membuat aplikasi gagal dibuka).
  static List<VisitRecord> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) VisitRecord.fromJson(item),
      ].whereType<VisitRecord>().toList();
    } catch (_) {
      return const [];
    }
  }
}

List<String> _strings(Object? v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
