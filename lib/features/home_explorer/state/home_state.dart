// lib/features/home_explorer/state/home_state.dart
// State UI03: ringkasan untuk header Home (PIC: Farella).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

class HomeSummary {
  const HomeSummary({required this.pois, required this.progress});
  final List<Poi> pois;
  final VisitProgress progress;
}

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final pois = await ref.watch(poisProvider.future);
  final progress = await ref.watch(progressProvider.future);
  return HomeSummary(pois: pois, progress: progress);
});
