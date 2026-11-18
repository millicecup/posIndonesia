// lib/features/progress/presentation/progress_screen.dart
// UI21 Progres & Rekomendasi (tab Progres, F07). Wireframe: PRD Gambar 5.7 kanan.
// Progres tersimpan permanen (shared_preferences). "Akhiri kunjungan" menutup sesi trigger,
// memberi cap kunjungan (A06), lalu membuka UI22 Ringkasan Kunjungan.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';

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
    final next = ref.watch(recommendedNextPoiProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres Kunjungan'),
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
                  'Semua kunjungan, perangko, dan riwayat cap akan dihapus.', 'Hapus')) {
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
                        Text('${p.stampCount} perangko, ${stats.quizCompleted} kuis selesai,'
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
            Text('Rekomendasi berikutnya',
                style: Theme.of(context).textTheme.titleMedium),
            if (next == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Semua koleksi sudah dikunjungi.'),
              )
            else
              Card(
                color: AppColors.orangeLight,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: AppColors.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(next.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${next.category.label}, Zona ${next.zone.code}'),
                  trailing: OutlinedButton(
                    onPressed: () => context.push(AppRoutes.navigateTo(next.id)),
                    child: const Text('Menuju'),
                  ),
                  onTap: () => context.push(AppRoutes.poiDetail(next.id)),
                ),
              ),
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
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                if (await _confirm(
                    context,
                    'Akhiri kunjungan?',
                    'Progres dan perangko tetap tersimpan, dan kamu akan mendapat cap '
                        'kunjungan digital. Pada kunjungan berikutnya semua POI bisa '
                        'memicu informasi lagi.',
                    'Akhiri')) {
                  await ref.read(visitSessionProvider).endVisit();
                  if (context.mounted) context.push(AppRoutes.summary);
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
