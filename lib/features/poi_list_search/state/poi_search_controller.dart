// lib/features/poi_list_search/state/poi_search_controller.dart
// State UI04: kata kunci + kategori terpilih -> hasil (PIC: Denaya).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../../../providers/providers.dart';

/// Kata kunci pencarian (nama atau kategori).
final poiSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// id kategori terpilih, null = semua.
final selectedCategoryIdProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Hasil gabungan: search(query) lalu filter kategori.
final poiSearchResultsProvider = FutureProvider.autoDispose<List<Poi>>((ref) async {
  final repo = ref.watch(poiRepositoryProvider);
  final query = ref.watch(poiSearchQueryProvider);
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final results = await repo.searchPois(query);
  if (categoryId == null) return results;
  return results.where((p) => p.category.id == categoryId).toList();
});
