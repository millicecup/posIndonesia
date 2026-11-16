// test/features/quiz_generator_test.dart
// Uji generator kuis A01: soal valid, jawaban benar ada di pilihan, tanpa pilihan ganda.

import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/features/quiz/state/quiz_generator.dart';

import '../helpers/test_data.dart';

void main() {
  final pois = loadDataset().where((p) => p.isBaseline).toList();

  test('soal otomatis: setiap POI baseline punya 3 soal dengan 4 pilihan unik', () {
    for (final poi in pois) {
      final questions = QuizGenerator.generated(poi, pois);
      expect(questions, hasLength(3), reason: poi.id);
      for (final q in questions) {
        expect(q.options, hasLength(QuizGenerator.optionCount), reason: q.prompt);
        expect(q.options.toSet(), hasLength(q.options.length), reason: q.prompt);
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
      }
    }
  });

  test('jawaban benar sesuai data POI', () {
    final poi = pois.firstWhere((p) => p.id == 'P04');
    final q = QuizGenerator.generated(poi, pois);
    expect(q[0].correctAnswer, poi.category.label);
    expect(q[1].correctAnswer, poi.zone.description);
    expect(q[2].correctAnswer, poi.systemResponse);
  });

  test('POI dengan soal tervalidasi memakai soal itu (P06, P08)', () {
    final p06 = pois.firstWhere((p) => p.id == 'P06');
    final p08 = pois.firstWhere((p) => p.id == 'P08');
    expect(QuizGenerator.forPoi(p06, pois), hasLength(5));
    expect(QuizGenerator.forPoi(p08, pois).first.correctAnswer, 'Semarang');
  });

  test('urutan pilihan deterministik per POI', () {
    final poi = pois.first;
    expect(QuizGenerator.forPoi(poi, pois).first.options,
        QuizGenerator.forPoi(poi, pois).first.options);
  });
}
