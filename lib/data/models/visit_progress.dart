// lib/data/models/visit_progress.dart
// Ringkasan progres kunjungan (F07) & koleksi perangko (F08).

class VisitProgress {
  const VisitProgress({
    required this.visitedPoiIds,
    required this.collectedStampIds,
    required this.totalPois,
    this.lastVisitedAt,
  });

  const VisitProgress.empty()
      : visitedPoiIds = const [],
        collectedStampIds = const [],
        totalPois = 0,
        lastVisitedAt = null;

  /// Urutan sesuai waktu kunjungan, tanpa duplikasi.
  final List<String> visitedPoiIds;
  final List<String> collectedStampIds;
  final int totalPois;
  final DateTime? lastVisitedAt;

  int get visitedCount => visitedPoiIds.length;
  int get stampCount => collectedStampIds.length;

  /// Persentase 0.0 - 1.0.
  double get completion =>
      totalPois == 0 ? 0 : (visitedCount / totalPois).clamp(0, 1).toDouble();

  int get completionPercent => (completion * 100).round();

  bool isVisited(String poiId) => visitedPoiIds.contains(poiId);
  bool hasStamp(String stampId) => collectedStampIds.contains(stampId);

  Map<String, dynamic> toJson() => {
        'visitedPoiIds': visitedPoiIds,
        'collectedStampIds': collectedStampIds,
        'totalPois': totalPois,
        'lastVisitedAt': lastVisitedAt?.toIso8601String(),
      };

  factory VisitProgress.fromJson(Map<String, dynamic> json) => VisitProgress(
        visitedPoiIds: (json['visitedPoiIds'] as List).cast<String>(),
        collectedStampIds: (json['collectedStampIds'] as List).cast<String>(),
        totalPois: (json['totalPois'] as num).toInt(),
        lastVisitedAt: json['lastVisitedAt'] == null
            ? null
            : DateTime.parse(json['lastVisitedAt'] as String),
      );

  VisitProgress copyWith({
    List<String>? visitedPoiIds,
    List<String>? collectedStampIds,
    int? totalPois,
    DateTime? lastVisitedAt,
  }) =>
      VisitProgress(
        visitedPoiIds: visitedPoiIds ?? this.visitedPoiIds,
        collectedStampIds: collectedStampIds ?? this.collectedStampIds,
        totalPois: totalPois ?? this.totalPois,
        lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      );

  @override
  String toString() =>
      'VisitProgress($visitedCount/$totalPois POI, $stampCount perangko)';
}
