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

  Future<void> clear() async {
    await _prefs.remove(AppConstants.prefVisitedIds);
    await _prefs.remove(AppConstants.prefStampIds);
    await _prefs.remove(AppConstants.prefLastVisitedAt);
    await clearSession();
  }
}
