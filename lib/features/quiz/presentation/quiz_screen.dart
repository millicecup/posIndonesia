// lib/features/quiz/presentation/quiz_screen.dart
// UI17 Kuis Sejarah (A01, PB15): pilihan ganda per POI, umpan balik per soal, hasil akhir.
// Wireframe: PRD Gambar 5.6 tengah.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../state/quiz_generator.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.poiId});

  final String poiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(poisProvider).valueOrNull;
    final poi = pois?.where((p) => p.id == poiId).firstOrNull;
    return Scaffold(
      appBar: JejakAppBar(title: Text(poi == null ? 'Kuis' : 'Kuis: ${poi.name}')),
      body: pois == null
          ? const Center(child: CircularProgressIndicator())
          : poi == null
              ? const Center(child: Text('POI tidak ditemukan'))
              : _QuizBody(poi: poi, questions: QuizGenerator.forPoi(poi, pois)),
    );
  }
}

class _QuizBody extends ConsumerStatefulWidget {
  const _QuizBody({required this.poi, required this.questions});
  final Poi poi;
  final List<QuizQuestion> questions;

  @override
  ConsumerState<_QuizBody> createState() => _QuizBodyState();
}

class _QuizBodyState extends ConsumerState<_QuizBody> {
  int _index = 0;
  int? _selected;
  bool _answered = false;
  final List<bool> _results = [];

  bool get _finished => _results.length == widget.questions.length && !_answered;

  void _submit() {
    if (_selected == null) return;
    setState(() {
      _answered = true;
      _results.add(_selected == widget.questions[_index].correctIndex);
    });
  }

  Future<void> _next() async {
    final isLast = _index == widget.questions.length - 1;
    setState(() {
      _answered = false;
      _selected = null;
      if (!isLast) _index++;
    });
    if (isLast) await ref.read(activityStatsProvider.notifier).addQuizCompleted();
  }

  void _restart() => setState(() {
        _index = 0;
        _selected = null;
        _answered = false;
        _results.clear();
      });

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(child: Text('Soal belum tersedia untuk koleksi ini.'));
    }
    if (_finished) return _buildResult();

    final q = widget.questions[_index];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pertanyaan ${_index + 1} dari ${widget.questions.length}',
                style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < widget.questions.length; i++)
                  Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i <= _index ? AppColors.darkGrey : AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(q.prompt, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  for (var i = 0; i < q.options.length; i++) _option(q, i),
                  if (_answered)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '${_results.last ? 'Benar!' : 'Kurang tepat.'} ${q.explanation}',
                        style: TextStyle(
                            color: _results.last ? AppColors.success : AppColors.danger),
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGrey),
              onPressed: _answered ? _next : (_selected == null ? null : _submit),
              child: Text(_answered
                  ? (_index == widget.questions.length - 1 ? 'Lihat hasil' : 'Lanjut')
                  : 'Jawab'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _option(QuizQuestion q, int i) {
    Color border = AppColors.lightGrey;
    Color? bg;
    if (_answered) {
      if (i == q.correctIndex) {
        border = AppColors.success;
        bg = const Color(0xFFE8F5E9);
      } else if (i == _selected) {
        border = AppColors.danger;
        bg = const Color(0xFFFFEBEE);
      }
    } else if (i == _selected) {
      border = AppColors.orange;
      bg = AppColors.orangeLight;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _answered ? null : () => setState(() => _selected = i),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(i == _selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: i == _selected ? AppColors.orange : AppColors.grey),
              const SizedBox(width: 10),
              Expanded(child: Text(q.options[i])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    final correct = _results.where((r) => r).length;
    final total = widget.questions.length;
    final great = correct == total;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(great ? Icons.emoji_events : Icons.school,
              size: 72, color: AppColors.orange),
          const SizedBox(height: 8),
          Text('Skor kamu: $correct / $total',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          Text(great ? 'Sempurna! Kamu menjelajah dengan teliti.' : 'Bagus! Coba lagi untuk skor penuh.',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          for (var i = 0; i < total; i++)
            ListTile(
              leading: Icon(_results[i] ? Icons.check_circle : Icons.cancel,
                  color: _results[i] ? AppColors.success : AppColors.danger),
              title: Text(widget.questions[i].prompt),
              subtitle: Text('Jawaban: ${widget.questions[i].correctAnswer}'),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pushReplacement(AppRoutes.poiDetail(widget.poi.id)),
            child: const Text('Kembali ke koleksi'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _restart, child: const Text('Ulangi kuis')),
        ],
      ),
    );
  }
}
