// lib/data/repositories/progress_repository.dart
// Kontrak progres kunjungan & perangko (disimpan lokal).

import '../models/visit_progress.dart';

abstract class ProgressRepository {
  /// Tandai POI dikunjungi. Return true jika baru (bukan duplikat).
  Future<bool> markVisited(String poiId);

  /// Simpan perangko. Return true jika baru (album tanpa duplikasi).
  Future<bool> collectStamp(String stampId);

  Future<List<String>> getVisitedIds();

  Future<List<String>> getCollectedStamps();

  Future<VisitProgress> getProgressSummary();

  Future<void> resetProgress();
}
