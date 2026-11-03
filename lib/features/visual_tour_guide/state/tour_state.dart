// lib/features/visual_tour_guide/state/tour_state.dart
// State UI09: rekomendasi POI berikutnya + progres (F07).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class TourState {
  const TourState({required this.next, required this.progress});
  final Poi? next;
  final VisitProgress progress;
}

final tourStateProvider = FutureProvider.autoDispose<TourState>((ref) async {
  final progress = await ref.watch(progressProvider.future);
  final next = await ref.watch(recommendedNextPoiProvider.future);
  return TourState(next: next, progress: progress);
});
