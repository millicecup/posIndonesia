// lib/data/models/poi.dart
// Model utama Point of Interest (POI) museum.

import '../../core/errors/app_exception.dart';
import '../../core/utils/json_utils.dart';
import 'map_position.dart';
import 'poi_category.dart';
import 'poi_content.dart';
import 'poi_zone.dart';
import 'stamp.dart';
import 'trigger_rule.dart';

/// Jenis konten POI, mengikuti kolom "Content" Tabel 4 PRD.
enum PoiContentType {
  text,
  image,
  audio,
  timeline,
  illustration,
  animation,
  simulation,
  map,
  game
}

/// Aktivitas/respons khusus POI (kolom "System Response" Tabel 4 PRD).
/// Sebagian besar dikerjakan sprint berikutnya (A01-A07, F08).
enum PoiActivity {
  timeline, // P01 timeline interaktif
  gallery, // P07, P09, P12 galeri (PRD v1: P03, P09, P11)
  quiz, // A01 (wireframe UI17: kuis Peralatan Pos, kini kandidat P12)
  mission, // A02 Jejak Misi (wireframe UI20: P03 v1, kini kandidat P12)
  minigame, // P06 cocokkan wilayah & kode pos (PRD v1: P08)
  mystery, // A05 Mystery Clue P08 (PRD v1 & teks A05: P10)
  photoStudio, // F08 Photo Studio P04 (PRD v1: P06)
  stampVisualization, // A04 lima tahap pembuatan prangko P05 (PRD v1 & teks A04: P07)
  postmark, // A06 Digital Postmark P11 (PRD v1: P12)
}

T _enumFromName<T extends Enum>(List<T> values, String name, String field) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw DataParseException('Nilai "$name" tidak dikenal untuk field $field');
}

class Poi {
  const Poi({
    required this.id,
    required this.tourOrder,
    required this.name,
    required this.category,
    required this.zone,
    required this.beaconId,
    required this.qrCode,
    required this.shortDescription,
    required this.keyFacts,
    required this.images,
    required this.audio,
    required this.contentTypes,
    required this.triggerRule,
    required this.systemResponse,
    required this.stamp,
    required this.mapPosition,
    required this.latitude,
    required this.longitude,
    required this.coordinatesArePlaceholder,
    required this.activities,
    required this.contentValidated,
    this.isBaseline = true,
    this.sections = const [],
    this.mysteryClues = const [],
    this.curatedQuiz = const [],
    this.contentSource,
    this.audioPlaceholder = false,
  });

  final String id;
  final int tourOrder;
  final String name;
  final PoiCategory category;
  final PoiZone zone;
  final String beaconId;
  final String qrCode;
  final String shortDescription;
  final List<String> keyFacts;
  final List<String> images;
  final String? audio;
  final List<PoiContentType> contentTypes;
  final TriggerRule triggerRule;
  final String systemResponse;
  final Stamp stamp;
  final MapPosition mapPosition;

  /// PLACEHOLDER sementara, bukan koordinat asli.
  final double? latitude;
  final double? longitude;
  final bool coordinatesArePlaceholder;

  /// Kosong = hanya interaksi inti (info, gambar, audio).
  final List<PoiActivity> activities;

  /// false = konten masih [PERLU VALIDASI MUSEUM].
  final bool contentValidated;

  /// true = POI ada di PRD v2 Tabel 4 (P01-P11).
  /// false = kandidat tambahan (NG08), dikerjakan setelah kebutuhan minimum terpenuhi.
  final bool isBaseline;

  /// Cerita lengkap per bagian (PB06). Kosong = belum ada materi tervalidasi.
  final List<PoiSection> sections;

  /// Petunjuk "Siapa aku?" untuk Mystery Clue (A05). Hanya dari materi tervalidasi.
  final List<String> mysteryClues;

  /// Soal kuis dari materi museum (dipakai lebih dulu daripada soal otomatis).
  final List<PoiQuizItem> curatedQuiz;

  /// Asal konten, misal "Dokumen Sprint 2 (PB06), tab revisi".
  final String? contentSource;

  /// true = file audio hanya nada placeholder; narasi dibacakan pemandu suara (TTS).
  final bool audioPlaceholder;

  bool get hasAudio => audio != null && audio!.isNotEmpty;

  /// Rekaman asli (mis. Mars Pos Indonesia), bukan placeholder.
  bool get hasRealAudio => hasAudio && !audioPlaceholder;
  bool get hasCoordinates => latitude != null && longitude != null;
  String? get coverImage => images.isEmpty ? null : images.first;
  bool get hasQuiz =>
      activities.contains(PoiActivity.quiz) && curatedQuiz.isNotEmpty;
  bool get hasCodeGame =>
      activities.contains(PoiActivity.minigame) && curatedQuiz.isNotEmpty;

  /// File yang boleh disajikan dari Firebase Hosting, bukan dari APK.
  List<String> get mediaPaths => {
        ...images,
        for (final s in sections) ...s.images,
        if (hasAudio) audio!,
      }.toList();

  factory Poi.fromJson(Map<String, dynamic> json) {
    final ctx = 'POI ${json['id'] ?? '(tanpa id)'}';
    return Poi(
      id: readRequired<String>(json, 'id', context: ctx),
      tourOrder: (json['tourOrder'] as num?)?.toInt() ?? 0,
      name: readRequired<String>(json, 'name', context: ctx),
      category: PoiCategory.fromJson(
          readRequired<Map<String, dynamic>>(json, 'category', context: ctx)),
      zone: PoiZone.fromJson(
          readRequired<Map<String, dynamic>>(json, 'zone', context: ctx)),
      beaconId: readRequired<String>(json, 'beaconId', context: ctx),
      qrCode: readRequired<String>(json, 'qrCode', context: ctx),
      shortDescription:
          readRequired<String>(json, 'shortDescription', context: ctx),
      keyFacts: readStringList(json, 'keyFacts', context: ctx),
      images: readStringList(json, 'images', context: ctx),
      audio: json['audio'] as String?,
      contentTypes: readStringList(json, 'contentTypes', context: ctx)
          .map((e) => _enumFromName(PoiContentType.values, e, 'contentTypes'))
          .toList(growable: false),
      triggerRule: TriggerRule.fromJson(readRequired<Map<String, dynamic>>(
          json, 'triggerRule',
          context: ctx)),
      systemResponse:
          readRequired<String>(json, 'systemResponse', context: ctx),
      stamp: Stamp.fromJson(
          readRequired<Map<String, dynamic>>(json, 'stamp', context: ctx)),
      mapPosition: MapPosition.fromJson(readRequired<Map<String, dynamic>>(
          json, 'mapPosition',
          context: ctx)),
      latitude: readNullableDouble(json, 'latitude'),
      longitude: readNullableDouble(json, 'longitude'),
      coordinatesArePlaceholder:
          (json['coordinatesArePlaceholder'] as bool?) ?? true,
      activities: ((json['activities'] as List?) ?? const [])
          .map((e) =>
              _enumFromName(PoiActivity.values, e.toString(), 'activities'))
          .toList(growable: false),
      contentValidated: (json['contentValidated'] as bool?) ?? false,
      isBaseline: (json['baseline'] as bool?) ?? true,
      sections: ((json['sections'] as List?) ?? const [])
          .map((e) => PoiSection.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      mysteryClues:
          ((json['mysteryClues'] as List?) ?? const []).cast<String>(),
      curatedQuiz: ((json['quiz'] as List?) ?? const [])
          .map((e) => PoiQuizItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      contentSource: json['contentSource'] as String?,
      audioPlaceholder: (json['audioPlaceholder'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tourOrder': tourOrder,
        'name': name,
        'category': category.toJson(),
        'zone': zone.toJson(),
        'beaconId': beaconId,
        'qrCode': qrCode,
        'shortDescription': shortDescription,
        'keyFacts': keyFacts,
        'images': images,
        'audio': audio,
        'contentTypes': contentTypes.map((e) => e.name).toList(),
        'triggerRule': triggerRule.toJson(),
        'systemResponse': systemResponse,
        'stamp': stamp.toJson(),
        'mapPosition': mapPosition.toJson(),
        'latitude': latitude,
        'longitude': longitude,
        'coordinatesArePlaceholder': coordinatesArePlaceholder,
        'activities': activities.map((e) => e.name).toList(),
        'contentValidated': contentValidated,
        'baseline': isBaseline,
        'sections': sections.map((e) => e.toJson()).toList(),
        'mysteryClues': mysteryClues,
        'quiz': curatedQuiz.map((e) => e.toJson()).toList(),
        'contentSource': contentSource,
        'audioPlaceholder': audioPlaceholder,
      };

  Poi copyWith({
    String? id,
    int? tourOrder,
    String? name,
    PoiCategory? category,
    PoiZone? zone,
    String? beaconId,
    String? qrCode,
    String? shortDescription,
    List<String>? keyFacts,
    List<String>? images,
    String? audio,
    List<PoiContentType>? contentTypes,
    TriggerRule? triggerRule,
    String? systemResponse,
    Stamp? stamp,
    MapPosition? mapPosition,
    double? latitude,
    double? longitude,
    bool? coordinatesArePlaceholder,
    List<PoiActivity>? activities,
    bool? contentValidated,
    bool? isBaseline,
  }) =>
      Poi(
        id: id ?? this.id,
        tourOrder: tourOrder ?? this.tourOrder,
        name: name ?? this.name,
        category: category ?? this.category,
        zone: zone ?? this.zone,
        beaconId: beaconId ?? this.beaconId,
        qrCode: qrCode ?? this.qrCode,
        shortDescription: shortDescription ?? this.shortDescription,
        keyFacts: keyFacts ?? this.keyFacts,
        images: images ?? this.images,
        audio: audio ?? this.audio,
        contentTypes: contentTypes ?? this.contentTypes,
        triggerRule: triggerRule ?? this.triggerRule,
        systemResponse: systemResponse ?? this.systemResponse,
        stamp: stamp ?? this.stamp,
        mapPosition: mapPosition ?? this.mapPosition,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        coordinatesArePlaceholder:
            coordinatesArePlaceholder ?? this.coordinatesArePlaceholder,
        activities: activities ?? this.activities,
        contentValidated: contentValidated ?? this.contentValidated,
        isBaseline: isBaseline ?? this.isBaseline,
        sections: sections,
        mysteryClues: mysteryClues,
        curatedQuiz: curatedQuiz,
        contentSource: contentSource,
        audioPlaceholder: audioPlaceholder,
      );

  /// POI dianggap sama jika id sama (id unik di dataset).
  @override
  bool operator ==(Object other) => other is Poi && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Poi($id, $name)';
}
