// lib/features/visit_summary/presentation/visit_summary_screen.dart
// UI22 Ringkasan kunjungan + Postmark (F07, A06, PB17). Wireframe: PRD Gambar 5.8 kiri.
// Cap kunjungan memuat tanggal kunjungan dan tersimpan setelah pengguna mengakhiri sesi.
// - DF-08: kartu paspor dengan animasi stempel (PassportPostmarkCard). Animasi hanya
//   diputar tepat setelah "Akhiri kunjungan"; dibuka dari riwayat = cap langsung tampil.
// - DF-05: ringkasan tiap kunjungan tersimpan permanen dan tampil lagi setelah app dibuka ulang.

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
import '../widgets/passport_postmark_card.dart';

/// Nama penjelajah di kartu paspor (tersimpan).
const visitorNamePrefKey = 'jejakpos.visitor_name';

String formatShortPostmark(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${(d.year % 100).toString().padLeft(2, '0')} • BDG';

class VisitSummaryScreen extends ConsumerWidget {
  const VisitSummaryScreen({super.key, this.justEnded = false});

  /// true = dibuka langsung setelah "Akhiri kunjungan" -> animasi stempel diputar.
  final bool justEnded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress =
        ref.watch(progressProvider).valueOrNull ?? const VisitProgress.empty();
    final stats = ref.watch(activityStatsProvider);
    final pois = ref.watch(poisProvider).valueOrNull ?? const <Poi>[];
    final collected =
        pois.where((p) => progress.hasStamp(p.stamp.id)).toList();
    final visits = stats.visits;
    final last = stats.lastVisit;
    final prefs = ref.watch(sharedPreferencesProvider);
    final poiNames = {for (final p in pois) p.id: p.name};

    return Scaffold(
      appBar: JejakAppBar(title: const Text('Ringkasan kunjungan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (last == null) ...[
            Center(
              child: Opacity(
                opacity: .35,
                child: PostmarkStamp(date: DateTime.now(), size: 170),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cap kunjungan digital akan diberikan saat kamu menekan '
              '"Akhiri kunjungan" di tab Progres.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ] else ...[
            PassportPostmarkCard(
              key: ValueKey(last.endedAt),
              visitorName:
                  prefs.getString(visitorNamePrefKey) ?? 'Penjelajah Pos',
              visitDate: formatPostmarkDate(last.endedAt),
              shortDate: formatShortPostmark(last.endedAt),
              totalVisits: visits.length,
              previousVisitDates: [
                for (final v in visits.take(visits.length - 1))
                  formatPostmarkDate(v.endedAt),
              ],
              triggerStampAnimation: justEnded,
              mascotAssetPath: 'assets/images/maskot_prangko_transparent.png',
              onVisitorNameChanged: (name) =>
                  prefs.setString(visitorNamePrefKey, name.trim()),
            ),
            const SizedBox(height: 8),
            Text(
              'Cap kunjungan digital (postmark): ${visits.length} kunjungan tercatat',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Text('Total aktivitas',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatBox(value: progress.visitedCount, label: 'POI'),
              _StatBox(value: progress.stampCount, label: 'Prangko'),
              _StatBox(value: stats.quizCompleted, label: 'Kuis'),
              _StatBox(value: stats.photoCount, label: 'Foto'),
            ],
          ),
          const SizedBox(height: 20),
          Text('Riwayat kunjungan',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          if (visits.isEmpty)
            const Text('Belum ada kunjungan yang diakhiri.',
                style: TextStyle(color: AppColors.grey))
          else
            for (var i = visits.length - 1; i >= 0; i--)
              VisitHistoryTile(
                  number: i + 1, record: visits[i], poiNames: poiNames),
          const SizedBox(height: 20),
          Text('Prangko terkumpul',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (collected.isEmpty)
            const Text(
                'Belum ada prangko. Selesaikan aktivitas POI untuk mendapatkannya.')
          else
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: collected.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => StampFrame(
                    image: collected[i].stamp.image,
                    random: collected[i].stamp.isRandom,
                    size: 80,
                    label: collected[i].id),
              ),
            ),
          const SizedBox(height: 16),
          Text('POI yang dikunjungi',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in pois)
                if (progress.isVisited(p.id))
                  Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: Text('${p.id}: ${p.name}',
                        style: const TextStyle(fontSize: 12)),
                  ),
            ],
          ),
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

/// Satu baris riwayat: tanggal cap + rincian aktivitas kunjungan itu.
class VisitHistoryTile extends StatelessWidget {
  const VisitHistoryTile(
      {super.key,
      required this.number,
      required this.record,
      this.poiNames = const {}});

  final int number;
  final VisitRecord record;
  final Map<String, String> poiNames;

  @override
  Widget build(BuildContext context) {
    final legacy = record.poiIds.isEmpty &&
        record.stampIds.isEmpty &&
        record.quizCompleted == 0 &&
        record.photoCount == 0 &&
        record.totalVisited == 0;
    final pois = record.poiIds.map((id) => poiNames[id] ?? id).join(', ');
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: const Icon(Icons.approval, color: AppColors.orange),
        title: Text(
            'Kunjungan #$number • ${formatPostmarkDate(record.endedAt)}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(legacy
            ? 'Cap kunjungan tersimpan.'
            : '${record.activityLine}'
                '${pois.isEmpty ? '' : '\nKoleksi baru: $pois'}'),
        isThreeLine: !legacy && pois.isNotEmpty,
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
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            ],
          ),
        ),
      );
}
