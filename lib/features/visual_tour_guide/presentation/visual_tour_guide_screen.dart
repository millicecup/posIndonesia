// lib/features/visual_tour_guide/presentation/visual_tour_guide_screen.dart
// UI09 Visual Tour Guide 2D (F07, PB12). Wireframe: PRD Gambar 5.4 kiri.
// - Dengan poiId (dibuka otomatis setelah trigger): dialog kontekstual 3 langkah tentang POI,
//   pilihan aksi (info singkat / narasi / aktivitas), dan rekomendasi berikutnya.
// - Tanpa poiId: pemandu umum yang mengarahkan ke rekomendasi berikutnya.
// Dialog disusun dari data POI (pois.json); tidak ada fakta sejarah yang ditulis di kode.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/postman_guide.dart';
import '../../../shared/widgets/progress_badge.dart';
import '../../poi_detail/presentation/poi_activity_launcher.dart';
import '../../voice_guide/presentation/listen_to_poi.dart';
import '../../voice_guide/presentation/voice_guide_bar.dart';
import '../../voice_guide/state/voice_guide_controller.dart';
import '../state/tour_state.dart';

class VisualTourGuideScreen extends ConsumerWidget {
  const VisualTourGuideScreen({super.key, this.poiId});

  final String? poiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(tourStateProvider);
    final poi =
        poiId == null ? null : ref.watch(poiByIdProvider(poiId!)).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(poi?.name ?? 'Pemandu Tur'),
        actions: [
          IconButton(
            tooltip: 'Kenali pameran (kamera)',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () => context.push(AppRoutes.visionTour),
          ),
          IconButton(
            tooltip: 'Tutup',
            icon: const Icon(Icons.close),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.explore),
          ),
        ],
      ),
      body: AsyncValueView<TourState>(
        value: tour,
        data: (t) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ProgressBadge(
                  visited: t.progress.visitedCount,
                  total: t.progress.totalPois),
            ),
            const SizedBox(height: 16),
            if (poi != null)
              _PoiDialog(poi: poi)
            else
              _GeneralDialog(next: t.next),
            const SizedBox(height: 16),
            if (t.next != null && t.next!.id != poi?.id)
              _NextCard(next: t.next!)
            else if (t.next == null)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.emoji_events, color: AppColors.orange),
                  title: Text('Semua koleksi sudah dikunjungi!'),
                  subtitle: Text(
                      'Akhiri kunjungan di tab Progres untuk mendapat cap kunjungan.'),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: VoiceGuideBar()),
    );
  }
}

/// Dialog kontekstual tentang POI yang sedang dikunjungi.
class _PoiDialog extends ConsumerStatefulWidget {
  const _PoiDialog({required this.poi});
  final Poi poi;

  @override
  ConsumerState<_PoiDialog> createState() => _PoiDialogState();
}

class _PoiDialogState extends ConsumerState<_PoiDialog> {
  int _step = 0;

  List<String> get _lines {
    final p = widget.poi;
    return [
      'Halo! Kamu sedang berada di area ${p.name} (${p.zone.description}).',
      p.shortDescription,
      if (p.keyFacts.isNotEmpty) 'Tahukah kamu? ${p.keyFacts.first}',
      'Di sini kamu bisa: ${p.systemResponse}. Pilih aksi di bawah, lalu ambil perangkonya!',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final poi = widget.poi;
    final lines = _lines;
    final last = _step >= lines.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SpeechBubble(text: lines[_step]),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dialog ${_step + 1} / ${lines.length}',
                style: const TextStyle(fontSize: 12, color: AppColors.grey)),
            TextButton(
              onPressed: () => setState(() => _step = last ? 0 : _step + 1),
              child: Text(last ? 'Ulangi' : 'Lanjut ›'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const PostmanGuide(size: 110),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.poiDetail(poi.id)),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Lihat info singkat'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(voiceGuideProvider.notifier).introducePoi(poi),
                    icon: const Icon(Icons.record_voice_over),
                    label: const Text('Dengarkan pemandu'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => listenToPoi(context, ref, poi),
                    icon: const Icon(Icons.headphones),
                    label: Text(poi.hasRealAudio
                        ? 'Putar Mars Pos'
                        : 'Dengarkan cerita lengkap'),
                  ),
                  for (final a in poi.activities)
                    OutlinedButton.icon(
                      onPressed: () => openPoiActivity(context, poi, a),
                      icon: Icon(poiActivityIcon(a)),
                      label: Text(poiActivityLabel(a)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GeneralDialog extends StatelessWidget {
  const _GeneralDialog({required this.next});
  final Poi? next;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SpeechBubble(
          text: next == null
              ? 'Hebat! Kamu sudah mengunjungi semua koleksi. Terima kasih sudah menjelajah!'
              : 'Halo, aku pemandu JejakPOS! Ayo lanjut ke ${next!.name} di '
                  '${next!.zone.description}. Saat kamu sampai, informasinya akan muncul otomatis.',
        ),
        const SizedBox(height: 8),
        const Center(child: PostmanGuide(size: 120)),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.grey),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35)),
      );
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.next});
  final Poi next;

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.orangeLight,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.orange),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: const Text('Rekomendasi berikutnya',
              style: TextStyle(fontSize: 12, color: AppColors.darkGrey)),
          subtitle: Text('${next.id} · ${next.name}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
          trailing: IconButton.filled(
            tooltip: 'Tunjukkan arah',
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.push(AppRoutes.navigateTo(next.id)),
          ),
          onTap: () => context.push(AppRoutes.poiDetail(next.id)),
        ),
      );
}
