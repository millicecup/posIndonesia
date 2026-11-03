// lib/features/poi_detail/state/poi_detail_state.dart
// State UI10: data POI + status perangko (PIC: Belinda).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class PoiDetailData {
  const PoiDetailData({
    required this.poi,
    required this.visited,
    required this.stampCollected,
  });

  final Poi poi;
  final bool visited;
  final bool stampCollected;
}

final poiDetailProvider =
    FutureProvider.autoDispose.family<PoiDetailData?, String>((ref, id) async {
  final poi = await ref.watch(poiByIdProvider(id).future);
  if (poi == null) return null;
  final progress = await ref.watch(progressProvider.future);
  return PoiDetailData(
    poi: poi,
    visited: progress.isVisited(poi.id),
    stampCollected: progress.hasStamp(poi.stamp.id),
  );
});
