import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/features/poi_detail/presentation/poi_activity_launcher.dart';
import 'package:jejakpos/features/quiz/presentation/quiz_screen.dart';
import 'package:jejakpos/providers/providers.dart';
import 'helpers/test_data.dart';

void main() {
  test('Only P02 and P08 offer curated quizzes; P06 keeps its code game', () {
    final pois = loadDataset().where((p) => p.isBaseline).toList();
    expect(pois.where((p) => p.hasQuiz).map((p) => p.id), ['P02', 'P08']);
    expect(pois.where((p) => p.hasCodeGame).map((p) => p.id), ['P06']);
    for (final p in pois.where((p) => p.hasQuiz || p.hasCodeGame)) {
      expect(p.curatedQuiz.length, 5, reason: p.id);
      expect(p.curatedQuiz.map((q) => q.question).toSet().length, 5);
    }
    final p04 = pois.firstWhere((p) => p.id == 'P04');
    expect(p04.activities, contains(PoiActivity.photoStudio));
    expect(p04.activities, isNot(contains(PoiActivity.timeline)));
    for (final id in ['P02', 'P03']) {
      expect(
          poiTimelineEntries(pois.firstWhere((p) => p.id == id)), hasLength(6));
    }
  });

  testWidgets('Direct quiz URL cannot generate a quiz for P04', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      poisProvider.overrideWith((ref) async => loadDataset()),
    ], child: const MaterialApp(home: QuizScreen(poiId: 'P04'))));
    await tester.pumpAndSettle();
    expect(find.text('Koleksi ini tidak memiliki kuis.'), findsOneWidget);
    expect(find.textContaining('Pertanyaan 1'), findsNothing);
  });
}
