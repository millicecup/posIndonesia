// lib/services/vision/vision_matcher.dart
// Pengenalan pameran: embedding frame kamera vs indeks foto referensi POI,
// digabung dengan koordinat GPS sebagai petunjuk lemah. Pure Dart -> mudah di-test.
//
// Alur: frame -> embedding (ImageEmbedder) -> rank() per POI (cosine similarity
//       - penalti jarak GPS) -> VisionStabilizer (N frame berturut-turut) -> POI.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetBundle;

import '../../core/config/app_config.dart';
import '../../core/utils/haversine.dart';
import '../../data/models/location_status.dart';
import '../../data/models/poi.dart';

/// Satu embedding referensi milik sebuah POI (sudah dinormalisasi panjang 1).
class VisionReference {
  const VisionReference({required this.poiId, required this.vector, this.source});

  final String poiId;
  final Float32List vector;
  final String? source;
}

/// Isi assets/models/poi_vision_index.json (dibuat tools/vision/build_vision_index.py).
class VisionIndex {
  VisionIndex({required this.dimension, required this.references});

  static const assetPath = 'assets/models/poi_vision_index.json';

  final int dimension;
  final List<VisionReference> references;

  Set<String> get poiIds => {for (final r in references) r.poiId};

  factory VisionIndex.fromJson(Map<String, dynamic> json) {
    final dim = json['dimension'] as int;
    final refs = <VisionReference>[];
    for (final raw in (json['entries'] as List).cast<Map<String, dynamic>>()) {
      final Float32List vector;
      if (raw['q'] is String) {
        // int8 terkuantisasi + skala
        final q = Int8List.view(base64Decode(raw['q'] as String).buffer);
        final scale = (raw['s'] as num).toDouble();
        vector = Float32List(q.length);
        for (var i = 0; i < q.length; i++) {
          vector[i] = q[i] * scale;
        }
      } else {
        vector = Float32List.fromList(
            (raw['vector'] as List).map((e) => (e as num).toDouble()).toList());
      }
      if (vector.length != dim) {
        throw FormatException('Embedding ${raw['poiId']} berdimensi ${vector.length}, '
            'seharusnya $dim');
      }
      refs.add(VisionReference(
        poiId: (raw['poiId'] as String).toUpperCase(),
        vector: normalize(vector),
        source: raw['source'] as String?,
      ));
    }
    return VisionIndex(dimension: dim, references: refs);
  }

  static Future<VisionIndex> load(AssetBundle bundle) async =>
      VisionIndex.fromJson(
          jsonDecode(await bundle.loadString(assetPath)) as Map<String, dynamic>);
}

/// Normalisasi L2 (salinan baru).
Float32List normalize(Float32List v) {
  var sum = 0.0;
  for (final x in v) {
    sum += x * x;
  }
  final n = math.sqrt(sum);
  final out = Float32List(v.length);
  if (n == 0) return out;
  for (var i = 0; i < v.length; i++) {
    out[i] = v[i] / n;
  }
  return out;
}

double _dot(Float32List a, Float32List b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += a[i] * b[i];
  }
  return s;
}

/// Skor satu POI untuk satu frame.
class VisionScore {
  const VisionScore({
    required this.poi,
    required this.similarity,
    required this.gpsPenalty,
    this.distanceMeters,
  });

  final Poi poi;

  /// Cosine similarity terbaik terhadap foto referensi POI ini (-1..1).
  final double similarity;

  /// Pengurang skor karena posisi GPS jauh dari POI (0 jika tidak ada GPS).
  final double gpsPenalty;
  final double? distanceMeters;

  double get score => similarity - gpsPenalty;

  @override
  String toString() =>
      'VisionScore(${poi.id}, sim ${similarity.toStringAsFixed(3)}, '
      'gps -${gpsPenalty.toStringAsFixed(3)})';
}

class VisionMatcher {
  VisionMatcher(this.index, {this.config = const AppConfig()});

  final VisionIndex index;
  final AppConfig config;

  /// Urutkan POI dari yang paling cocok. POI tanpa foto referensi dilewati.
  /// [position] opsional: GPS dipakai sebagai penalti lembut, bukan filter.
  List<VisionScore> rank(Float32List embedding,
      {required List<Poi> pois, UserPosition? position}) {
    final e = normalize(embedding);
    final best = <String, double>{};
    for (final r in index.references) {
      final s = _dot(e, r.vector);
      final prev = best[r.poiId];
      if (prev == null || s > prev) best[r.poiId] = s;
    }

    final usableGps = position != null &&
        position.accuracyMeters <= config.maxAcceptedAccuracyMeters;
    final scores = <VisionScore>[];
    for (final poi in pois) {
      final sim = best[poi.id.toUpperCase()];
      if (sim == null) continue;
      double? distance;
      var penalty = 0.0;
      if (usableGps && poi.hasCoordinates) {
        distance = haversineDistanceMeters(
            position.latitude, position.longitude, poi.latitude!, poi.longitude!);
        final excess =
            distance - position.accuracyMeters - config.visionGpsSlackMeters;
        if (excess > 0) {
          penalty = math.min(config.visionGpsMaxPenalty,
              excess * config.visionGpsPenaltyPerMeter);
        }
      }
      scores.add(VisionScore(
          poi: poi, similarity: sim, gpsPenalty: penalty, distanceMeters: distance));
    }
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores;
  }
}

enum VisionPhase {
  /// Belum ada pameran yang cukup mirip.
  searching,

  /// Dua POI teratas terlalu mirip skornya.
  ambiguous,

  /// POI teratas konsisten, menunggu frame berikutnya.
  recognizing,

  /// POI dikonfirmasi.
  confirmed,
}

class VisionDecision {
  const VisionDecision({
    required this.phase,
    this.top,
    this.runnerUp,
    this.streak = 0,
    this.requiredFrames = 1,
  });

  final VisionPhase phase;
  final VisionScore? top;
  final VisionScore? runnerUp;
  final int streak;
  final int requiredFrames;

  double get progress => (streak / requiredFrames).clamp(0, 1).toDouble();
  Poi? get confirmedPoi => phase == VisionPhase.confirmed ? top?.poi : null;
}

/// Mencegah tebakan berkedip: POI harus menang N frame berturut-turut
/// dengan skor dan selisih yang cukup.
class VisionStabilizer {
  VisionStabilizer({this.config = const AppConfig()});

  final AppConfig config;
  String? _candidate;
  int _streak = 0;

  void reset() {
    _candidate = null;
    _streak = 0;
  }

  VisionDecision feed(List<VisionScore> ranked) {
    final need = config.visionRequiredFrames;
    final top = ranked.isEmpty ? null : ranked.first;
    final second = ranked.length > 1 ? ranked[1] : null;

    if (top == null || top.score < config.visionMinSimilarity) {
      reset();
      return VisionDecision(
          phase: VisionPhase.searching, top: top, runnerUp: second, requiredFrames: need);
    }
    final margin = top.score - (second?.score ?? -1);
    if (margin < config.visionMinMargin) {
      reset();
      return VisionDecision(
          phase: VisionPhase.ambiguous, top: top, runnerUp: second, requiredFrames: need);
    }

    if (_candidate == top.poi.id) {
      _streak++;
    } else {
      _candidate = top.poi.id;
      _streak = 1;
    }
    return VisionDecision(
      phase: _streak >= need ? VisionPhase.confirmed : VisionPhase.recognizing,
      top: top,
      runnerUp: second,
      streak: _streak,
      requiredFrames: need,
    );
  }
}
