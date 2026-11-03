// lib/features/progress/presentation/progress_screen.dart
// UI21 Progres & Rekomendasi (tab Progres, F07). Wireframe: PRD Gambar 5.7 kanan.
// Progres tersimpan permanen (shared_preferences). "Akhiri kunjungan" menutup sesi trigger.
// TODO(Farella): lingkaran 5/13, kartu rekomendasi dengan tombol "Menuju",
//   chip "Sudah dikunjungi", dan UI22 Ringkasan Kunjungan + Postmark (Sprint 4).

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
    final pois = ref.watch(poisProvider).valueOrNull ?? const <Poi>[];
    final next = ref.watch(recommendedNextPoiProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progres Kunjungan'),
        actions: [
          IconButton(
            tooltip: 'Hapus semua progres',
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              if (await _confirm(context, 'Hapus progres?',
                  'Semua kunjungan dan perangko akan dihapus.', 'Hapus')) {
                await ref.read(progressProvider.notifier).reset();
                ref.read(triggerEngineProvider).resetSession();
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
            Text('${p.visitedCount}/${p.totalPois} POI dikunjungi',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: p.completion,
              minHeight: 10,
              color: AppColors.orange,
              backgroundColor: AppColors.lightGrey,
            ),
            const SizedBox(height: 8),
            Text('${p.completionPercent}% · ${p.stampCount} perangko'),
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
                child: ListTile(
                  title: Text(next.name),
                  subtitle: Text('${next.category.label} · Zona ${next.zone.code}'),
                  trailing: OutlinedButton(
                    onPressed: () => context.push(AppRoutes.navigateTo(next.id)),
                    child: const Text('Menuju'),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text('Sudah dikunjungi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
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
              onPressed: () async {
                if (await _confirm(
                    context,
                    'Akhiri kunjungan?',
                    'Progres dan perangko tetap tersimpan. Pada kunjungan berikutnya '
                        'semua POI bisa memicu informasi lagi.',
                    'Akhiri')) {
                  await ref.read(visitSessionProvider).endVisit();
                  if (context.mounted) {
                    // TODO(Sprint 4, PB17): buka UI22 Ringkasan Kunjungan + Postmark.
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Kunjungan diakhiri. Terima kasih!')));
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
