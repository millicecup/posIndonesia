// lib/data/repositories/progress_repository_impl.dart
// Implementasi ProgressRepository dengan shared_preferences (PIC: Matilda).

import '../../core/utils/app_logger.dart';
import '../datasources/progress_local_datasource.dart';
import '../models/visit_progress.dart';
import 'poi_repository.dart';
import 'progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._local, this._poiRepository);

  final ProgressLocalDataSource _local;
  final PoiRepository _poiRepository;

  static const _tag = 'PROGRES';

  @override
  Future<bool> markVisited(String poiId) async {
    final id = poiId.trim().toUpperCase();
    final current = _local.readVisitedIds();
    if (current.contains(id)) return false;
    await _local.writeVisitedIds([...current, id]);
    await _local.writeLastVisitedAt(DateTime.now());
    AppLogger.info(_tag, 'POI $id ditandai dikunjungi');
    return true;
  }

  @override
  Future<bool> collectStamp(String stampId) async {
    final id = stampId.trim().toUpperCase();
    final current = _local.readStampIds();
    if (current.contains(id)) {
      AppLogger.info(_tag, 'Perangko $id sudah ada di album (tidak diduplikasi)');
      return false;
    }
    await _local.writeStampIds([...current, id]);
    AppLogger.info(_tag, 'Perangko $id disimpan ke album');
    return true;
  }

  @override
  Future<List<String>> getVisitedIds() async =>
      List.unmodifiable(_local.readVisitedIds());

  @override
  Future<List<String>> getCollectedStamps() async =>
      List.unmodifiable(_local.readStampIds());

  @override
  Future<VisitProgress> getProgressSummary() async {
    final pois = await _poiRepository.getAllPois();
    final validIds = pois.map((p) => p.id).toSet();
    return VisitProgress(
      // Abaikan id lama yang sudah tidak ada di dataset.
      visitedPoiIds: List.unmodifiable(
          _local.readVisitedIds().where(validIds.contains)),
      collectedStampIds: List.unmodifiable(_local.readStampIds()),
      totalPois: pois.length,
      lastVisitedAt: _local.readLastVisitedAt(),
    );
  }

  @override
  Future<void> resetProgress() async {
    await _local.clear();
    AppLogger.info(_tag, 'Progres direset');
  }
}
