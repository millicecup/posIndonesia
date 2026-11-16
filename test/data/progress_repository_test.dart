// test/data/progress_repository_test.dart
// Uji progres: tanpa duplikasi perangko/kunjungan & tetap tersimpan.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/data/datasources/progress_local_datasource.dart';
import 'package:jejakpos/data/repositories/progress_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late ProgressRepositoryImpl repo;

  ProgressRepositoryImpl newRepo() =>
      ProgressRepositoryImpl(ProgressLocalDataSource(prefs), buildRepository());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = newRepo();
  });

  test('collectStamp tidak menduplikasi perangko', () async {
    expect(await repo.collectStamp('STP-P01'), isTrue);
    expect(await repo.collectStamp('STP-P01'), isFalse);
    expect(await repo.collectStamp('stp-p01'), isFalse);
    expect(await repo.getCollectedStamps(), ['STP-P01']);
  });

  test('markVisited tidak menduplikasi kunjungan', () async {
    await repo.markVisited('P01');
    await repo.markVisited('P01');
    await repo.markVisited('P02');
    expect(await repo.getVisitedIds(), ['P01', 'P02']);
  });

  test('data tetap ada saat repository dibuat ulang (simulasi app dibuka lagi)',
      () async {
    await repo.markVisited('P03');
    await repo.collectStamp('STP-P03');
    final reopened = newRepo();
    expect(await reopened.getVisitedIds(), ['P03']);
    expect(await reopened.getCollectedStamps(), ['STP-P03']);
  });

  test('getProgressSummary menghitung persentase', () async {
    await repo.markVisited('P01');
    final summary = await repo.getProgressSummary();
    expect(summary.totalPois, 11); // hanya POI baseline PRD v2 (P12-P13 backlog)
    expect(summary.visitedCount, 1);
    expect(summary.completionPercent, 9); // 1 dari 11
    expect(summary.lastVisitedAt, isNotNull);
  });

  test('resetProgress menghapus semua', () async {
    await repo.markVisited('P01');
    await repo.collectStamp('STP-P01');
    await repo.resetProgress();
    expect(await repo.getVisitedIds(), isEmpty);
    expect(await repo.getCollectedStamps(), isEmpty);
  });

  test('sesi kunjungan tersimpan, dan clearSession tidak menghapus progres', () async {
    final local = ProgressLocalDataSource(prefs);
    await repo.markVisited('P01');
    await local.writeSessionTriggeredIds(['P01']);
    expect(ProgressLocalDataSource(prefs).readSessionTriggeredIds(), ['P01']);

    await local.clearSession(); // "Akhiri kunjungan"
    expect(local.readSessionTriggeredIds(), isEmpty);
    expect(await repo.getVisitedIds(), ['P01']);
  });
}
