import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jejakpos/app/theme.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/features/poi_detail/presentation/poi_detail_screen.dart';
import 'package:jejakpos/features/poi_detail/state/poi_detail_state.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/services/media_service.dart';
import 'helpers/test_data.dart';

class _Progress extends ProgressController {
  @override
  Future<VisitProgress> build() async => const VisitProgress.empty();
  @override
  Future<bool> markVisited(String poiId) async => true;
}

void main() {
  testWidgets(
      'P08 opens mystery first; correct answer unlocks detail without looping',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final poi = loadDataset().firstWhere((p) => p.id == 'P08');
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          progressProvider.overrideWith(_Progress.new),
          poiByIdProvider('P08').overrideWith((ref) async => poi),
          poiDetailProvider('P08').overrideWith((ref) async =>
              PoiDetailData(poi: poi, visited: true, stampCollected: false)),
          mediaSourceProvider
              .overrideWith((ref, args) async => BundledMedia(args.path)),
        ],
        child: MaterialApp(
            theme: AppTheme.light, home: const PoiDetailScreen(poiId: 'P08'))));
    await tester.pumpAndSettle();
    expect(find.text('Siapa aku?'), findsOneWidget);
    expect(find.text('Ringkasan cerita'), findsNothing);
    await tester.ensureVisible(find.text('R. Dijar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('R. Dijar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum tepat'), findsOneWidget);
    await tester.ensureVisible(find.text('Mas Soeharto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mas Soeharto'));
    await tester.pumpAndSettle();
    expect(find.text('Benar, aku Mas Soeharto!'), findsOneWidget);
    expect(find.text('Jawab 5 pertanyaan'), findsNothing);
    await tester.ensureVisible(find.text('Lihat detail koleksi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat detail koleksi'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan cerita'), findsOneWidget);
    expect(find.text('Siapa aku?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
