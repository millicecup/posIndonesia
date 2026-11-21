// lib/features/visit_summary/presentation/visit_summary_screen.dart
// UI22 Ringkasan kunjungan + Postmark (F07, A06, PB17). Wireframe: PRD Gambar 5.8 kiri.
// Cap kunjungan memuat tanggal kunjungan dan tersimpan setelah pengguna mengakhiri sesi.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/postmark_stamp.dart';
import '../../../shared/widgets/stamp_unlocked_dialog.dart';

class VisitSummaryScreen extends ConsumerWidget {
  const VisitSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider).valueOrNull ?? const VisitProgress.empty();
    final stats = ref.watch(activityStatsProvider);
    final pois = ref.watch(poisProvider).valueOrNull ?? const <Poi>[];
    final collected = pois.where((p) => progress.hasStamp(p.stamp.id)).toList();
    final postmark = stats.lastPostmark;

    return Scaffold(
      appBar: JejakAppBar(title: const Text('Ringkasan kunjungan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Opacity(
              opacity: postmark == null ? .35 : 1,
              child: PostmarkStamp(date: postmark ?? DateTime.now(), size: 170),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            postmark == null
                ? 'Cap kunjungan digital akan diberikan saat kamu menekan "Akhiri kunjungan" di tab Progres.'
                : 'Cap kunjungan digital (postmark): ${stats.postmarks.length} kunjungan tercatat',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(value: progress.visitedCount, label: 'POI'),
              _StatBox(value: progress.stampCount, label: 'Prangko'),
              _StatBox(value: stats.quizCompleted, label: 'Kuis'),
              _StatBox(value: stats.photoCount, label: 'Foto'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Prangko terkumpul', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (collected.isEmpty)
            const Text('Belum ada prangko. Selesaikan aktivitas POI untuk mendapatkannya.')
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: collected.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => StampFrame(
                    image: collected[i].stamp.image,
                    random: collected[i].stamp.isRandom, size: 80, label: collected[i].id),
              ),
            ),
          const SizedBox(height: 16),
          Text('POI yang dikunjungi', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in pois)
                if (progress.isVisited(p.id))
                  Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: Text('${p.id}: ${p.name}', style: const TextStyle(fontSize: 12)),
                  ),
            ],
          ),
          if (stats.postmarks.length > 1) ...[
            const SizedBox(height: 16),
            Text('Riwayat kunjungan', style: Theme.of(context).textTheme.titleMedium),
            for (final d in stats.postmarks.reversed)
              ListTile(
                dense: true,
                leading: const Icon(Icons.approval, color: AppColors.orange),
                title: Text(formatPostmarkDate(d)),
              ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.explore),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.lightGrey, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text('$value',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          ),
        ),
      );
}
