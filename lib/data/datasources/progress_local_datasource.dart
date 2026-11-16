// lib/data/datasources/progress_local_datasource.dart
// Simpan progres ke shared_preferences agar tetap ada setelah app ditutup (F07).

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class ProgressLocalDataSource {
  ProgressLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  List<String> readVisitedIds() =>
      _prefs.getStringList(AppConstants.prefVisitedIds) ?? const [];

  Future<void> writeVisitedIds(List<String> ids) =>
      _prefs.setStringList(AppConstants.prefVisitedIds, ids);

  List<String> readStampIds() =>
      _prefs.getStringList(AppConstants.prefStampIds) ?? const [];

  Future<void> writeStampIds(List<String> ids) =>
      _prefs.setStringList(AppConstants.prefStampIds, ids);

  DateTime? readLastVisitedAt() {
    final raw = _prefs.getString(AppConstants.prefLastVisitedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> writeLastVisitedAt(DateTime time) =>
      _prefs.setString(AppConstants.prefLastVisitedAt, time.toIso8601String());

  // ---- Sesi kunjungan (PRD 4.2: "sudah dipicu pada sesi ini?") ----

  List<String> readSessionTriggeredIds() =>
      _prefs.getStringList(AppConstants.prefSessionTriggeredIds) ?? const [];

  Future<void> writeSessionTriggeredIds(List<String> ids) =>
      _prefs.setStringList(AppConstants.prefSessionTriggeredIds, ids);

  Future<void> clearSession() =>
      _prefs.remove(AppConstants.prefSessionTriggeredIds);

  // ---- Statistik aktivitas & postmark (UI22, A01, A06, F08) ----

  int readQuizCompleted() => _prefs.getInt(AppConstants.prefQuizCompleted) ?? 0;

  Future<void> writeQuizCompleted(int value) =>
      _prefs.setInt(AppConstants.prefQuizCompleted, value);

  int readPhotoCount() => _prefs.getInt(AppConstants.prefPhotoCount) ?? 0;

  Future<void> writePhotoCount(int value) =>
      _prefs.setInt(AppConstants.prefPhotoCount, value);

  /// Tanggal cap kunjungan (ISO-8601), urut dari yang terlama.
  List<DateTime> readPostmarks() =>
      (_prefs.getStringList(AppConstants.prefPostmarks) ?? const [])
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList();

  Future<void> writePostmarks(List<DateTime> dates) => _prefs.setStringList(
      AppConstants.prefPostmarks, dates.map((d) => d.toIso8601String()).toList());

  int? readRandomStampSeed() => _prefs.getInt(AppConstants.prefRandomStampSeed);

  Future<void> writeRandomStampSeed(int seed) =>
      _prefs.setInt(AppConstants.prefRandomStampSeed, seed);

  Future<void> clear() async {
    await _prefs.remove(AppConstants.prefRandomStampSeed);
    await _prefs.remove(AppConstants.prefQuizCompleted);
    await _prefs.remove(AppConstants.prefPhotoCount);
    await _prefs.remove(AppConstants.prefPostmarks);
    await _prefs.remove(AppConstants.prefVisitedIds);
    await _prefs.remove(AppConstants.prefStampIds);
    await _prefs.remove(AppConstants.prefLastVisitedAt);
    await clearSession();
  }
}
