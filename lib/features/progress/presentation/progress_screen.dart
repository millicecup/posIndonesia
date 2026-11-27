// lib/features/progress/presentation/progress_screen.dart
// UI21 Progres & Rekomendasi (tab Progres, F07). Wireframe: PRD Gambar 5.7 kanan.
// Progres tersimpan permanen (shared_preferences). "Akhiri kunjungan" menutup sesi trigger,
// memberi cap kunjungan (A06), lalu membuka UI22 Ringkasan kunjungan.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../visit_summary/presentation/visit_summary_screen.dart';
import '../../visual_tour_guide/presentation/guide_next_stop_card.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  Future<bool> _confirm(BuildContext context, String title, String message,
      String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final stats = ref.watch(activityStatsProvider);
    final pois = ref.watch(poisProvider).valueOrNull ?? const <Poi>[];
    final nextAsync = ref.watch(recommendedNextPoiProvider);

    return Scaffold(
      appBar: JejakAppBar(
        title: const Text('Progres kunjungan'),
        actions: [
          IconButton(
            tooltip: 'Ringkasan kunjungan',
            icon: const Icon(Icons.approval),
            onPressed: () => context.push(AppRoutes.summary),
          ),
          IconButton(
            tooltip: 'Hapus semua progres',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              if (await _confirm(context, 'Hapus progres?',
                  'Semua kunjungan, prangko, dan riwayat cap akan dihapus.', 'Hapus')) {
                await ref.read(progressProvider.notifier).reset();
                ref.read(triggerEngineProvider).resetSession();
                ref.invalidate(activityStatsProvider);
              }
            },
          ),
        ],
      ),
      body: AsyncValueView<VisitProgress>(
        value: progress,
        data: (p) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGrey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: p.completion,
                          strokeWidth: 8,
                          color: AppColors.darkGrey,
                          backgroundColor: AppColors.lightGrey,
                        ),
                        Center(
                          child: Text('${p.visitedCount}/${p.totalPois}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('POI dikunjungi',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text('${p.stampCount} prangko, ${stats.quizCompleted} kuis selesai,'
                            ' dan ${stats.photoCount} foto'),
                        Text('${p.completionPercent}% koleksi dijelajahi',
                            style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // DF-07: saran pemandu yang sama dengan Jelajah & Pemandu tur.
            if (nextAsync.hasValue)
              GuideNextStopCard(next: nextAsync.value)
            else
              const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text('Sudah dikunjungi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (p.visitedCount == 0)
              const Text('Belum ada. Dekati koleksi atau pindai QR untuk mulai.',
                  style: TextStyle(color: AppColors.grey)),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final poi in pois)
                  if (p.isVisited(poi.id))
                    ActionChip(
                      avatar: const Icon(Icons.check, size: 16),
                      label: Text(poi.id),
                      onPressed: () => context.push(AppRoutes.poiDetail(poi.id)),
                    ),
              ],
            ),
            // DF-05: riwayat kunjungan tersimpan permanen, terlihat walau app dibuka ulang.
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text('Riwayat kunjungan',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (stats.visits.isNotEmpty)
                  Flexible(
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.summary),
                      child: const Text('Lihat ringkasan',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
              ],
            ),
            if (stats.visits.isEmpty)
              const Text(
                  'Belum ada. Tekan "Akhiri kunjungan" untuk menyimpan ringkasan '
                  'dan mendapat cap kunjungan.',
                  style: TextStyle(color: AppColors.grey))
            else
              for (var i = stats.visits.length - 1;
                  i >= 0 && i >= stats.visits.length - 3;
                  i--)
                VisitHistoryTile(
                  number: i + 1,
                  record: stats.visits[i],
                  poiNames: {for (final poi in pois) poi.id: poi.name},
                ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                if (await _confirm(
                    context,
                    'Akhiri kunjungan?',
                    'Progres dan prangko tetap tersimpan, dan kamu akan mendapat cap '
                        'kunjungan digital. Pada kunjungan berikutnya semua POI bisa '
                        'memicu informasi lagi.',
                    'Akhiri')) {
                  await ref.read(visitSessionProvider).endVisit();
                  if (context.mounted) {
                    context.push(AppRoutes.summaryAfterVisit);
                  }
                }
              },
              child: const Text('Akhiri kunjungan'),
            ),
          ],
        ),
      ),
    );
  }
}
