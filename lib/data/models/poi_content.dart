// lib/data/models/poi_content.dart
// Konten tervalidasi POI (PB06, Dokumen Sprint 2 tab revisi): cerita lengkap per bagian
// dan soal kuis yang jawabannya bersumber dari materi museum.

import '../../core/errors/app_exception.dart';
import '../../core/utils/json_utils.dart';

/// Satu bagian cerita POI, misalnya "Seragam Petugas Pos" atau "Lencana" di P04.
class PoiSection {
  const PoiSection({required this.title, required this.body, this.images = const []});

  final String title;

  /// Paragraf dipisah baris kosong ("\n\n").
  final String body;
  final List<String> images;

  List<String> get paragraphs =>
      body.split('\n\n').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

  factory PoiSection.fromJson(Map<String, dynamic> json) => PoiSection(
        title: readRequired<String>(json, 'title', context: 'sections'),
        body: readRequired<String>(json, 'body', context: 'sections'),
        images: ((json['images'] as List?) ?? const []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {'title': title, 'body': body, 'images': images};
}

/// Soal pilihan ganda dengan jawaban dari materi museum (A01, A05).
class PoiQuizItem {
  const PoiQuizItem({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  factory PoiQuizItem.fromJson(Map<String, dynamic> json) {
    final options = readStringList(json, 'options', context: 'quiz');
    final answer = (json['answerIndex'] as num?)?.toInt() ?? -1;
    if (answer < 0 || answer >= options.length) {
      throw DataParseException('quiz: answerIndex $answer di luar pilihan');
    }
    return PoiQuizItem(
      question: readRequired<String>(json, 'question', context: 'quiz'),
      options: options,
      answerIndex: answer,
      explanation: readRequired<String>(json, 'explanation', context: 'quiz'),
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'answerIndex': answerIndex,
        'explanation': explanation,
      };
}
