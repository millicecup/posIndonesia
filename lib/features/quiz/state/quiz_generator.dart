// lib/features/quiz/state/quiz_generator.dart
// Generator soal kuis per POI (A01, UI17).
// Soal disusun HANYA dari data struktur PRD Tabel 4 (kategori, zona, system response) yang ada
// di pois.json, bukan dari fakta sejarah karangan. Setelah konten divalidasi museum (PB06),
// soal dari keyFacts bisa ditambahkan.

import 'dart:math';

import '../../../data/models/models.dart';

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  String get correctAnswer => options[correctIndex];
}

class QuizGenerator {
  QuizGenerator._();

  static const int optionCount = 4;

  /// Soal untuk [target]: soal tervalidasi museum (pois.json "quiz") bila ada,
  /// selain itu tiga soal otomatis dari data Tabel 4.
  static List<QuizQuestion> forPoi(Poi target, List<Poi> all) {
    if (target.curatedQuiz.isNotEmpty) {
      return [
        for (final q in target.curatedQuiz)
          QuizQuestion(
            prompt: q.question,
            options: q.options,
            correctIndex: q.answerIndex,
            explanation: q.explanation,
          ),
      ];
    }
    return generated(target, all);
  }

  /// Tiga soal pilihan ganda otomatis tentang [target]. Urutan pilihan deterministik per POI.
  static List<QuizQuestion> generated(Poi target, List<Poi> all) {
    final random = Random(target.id.codeUnits.fold<int>(0, (a, b) => a * 31 + b));
    final others = all.where((p) => p.id != target.id).toList();

    QuizQuestion? build(String prompt, String Function(Poi) field, String explanation) {
      final correct = field(target);
      final distractors = <String>{};
      for (final p in others..shuffle(random)) {
        final v = field(p);
        if (v != correct) distractors.add(v);
        if (distractors.length == optionCount - 1) break;
      }
      if (distractors.isEmpty) return null;
      final options = [correct, ...distractors]..shuffle(random);
      return QuizQuestion(
        prompt: prompt,
        options: List.unmodifiable(options),
        correctIndex: options.indexOf(correct),
        explanation: explanation,
      );
    }

    return [
      build('Koleksi "${target.name}" termasuk kategori apa?', (p) => p.category.label,
          '${target.name} termasuk kategori ${target.category.label}.'),
      build('Di area mana kamu bisa menemukan "${target.name}"?', (p) => p.zone.description,
          'Koleksi ini ada di zona ${target.zone.code}: ${target.zone.description}.'),
      build('Apa yang bisa kamu temukan di JejakPOS saat mengunjungi "${target.name}"?',
          (p) => p.systemResponse,
          'Di koleksi ini JejakPOS menyediakan: ${target.systemResponse}.'),
    ].whereType<QuizQuestion>().toList(growable: false);
  }
}
