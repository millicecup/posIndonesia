// lib/features/poi_detail/presentation/poi_activity_launcher.dart
// Membuka aktivitas khusus POI (kolom "System Response" PRD Tabel 4). Dipakai UI09 & UI10.
// Aktivitas yang isinya butuh konten tervalidasi museum (Mystery Clue A05, mini-game kode pos)
// sengaja belum berisi soal: menampilkan keterangan, bukan fakta karangan (PRD R2, PB06).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../shared/widgets/media_image.dart';

String poiActivityLabel(PoiActivity a) => switch (a) {
      PoiActivity.timeline => 'Timeline interaktif',
      PoiActivity.gallery => 'Galeri',
      PoiActivity.quiz => 'Kuis',
      PoiActivity.mission => 'Jejak Misi',
      PoiActivity.minigame => 'Mini-game: cocokkan kode pos',
      PoiActivity.mystery => 'Mystery Clue: Siapa aku?',
      PoiActivity.photoStudio => 'Coba Photo Studio',
      PoiActivity.stampVisualization => 'Lihat 5 tahap pembuatan prangko',
      PoiActivity.postmark => 'Digital Postmark',
    };

IconData poiActivityIcon(PoiActivity a) => switch (a) {
      PoiActivity.timeline => Icons.timeline,
      PoiActivity.gallery => Icons.photo_library_outlined,
      PoiActivity.quiz => Icons.quiz_outlined,
      PoiActivity.mission => Icons.flag_outlined,
      PoiActivity.minigame => Icons.videogame_asset_outlined,
      PoiActivity.mystery => Icons.help_outline,
      PoiActivity.photoStudio => Icons.camera_alt_outlined,
      PoiActivity.stampVisualization => Icons.print_outlined,
      PoiActivity.postmark => Icons.approval_outlined,
    };

void openPoiActivity(BuildContext context, Poi poi, PoiActivity activity) {
  switch (activity) {
    case PoiActivity.photoStudio:
      context.push(AppRoutes.photoStudio(poi.id));
    case PoiActivity.stampVisualization:
      context.push(AppRoutes.stampMaking(poi.id));
    case PoiActivity.quiz:
      context.push(AppRoutes.quiz(poi.id));
    case PoiActivity.postmark:
      context.push(AppRoutes.summary);
    case PoiActivity.gallery:
      showPoiGallery(context, poi);
    case PoiActivity.timeline:
      _showTimeline(context, poi);
    case PoiActivity.minigame:
      // Soal "cocokkan angka pertama kode pos dengan wilayah" dari materi PB06 (pois.json "quiz").
      if (poi.curatedQuiz.isNotEmpty) {
        context.push(AppRoutes.quiz(poi.id));
      } else {
        _showPending(
            context,
            'Mini-game kode pos',
            'Mini-game mencocokkan wilayah dan kode pos akan aktif setelah data kode pos '
                'siap. Sementara itu, coba kuis koleksi ini.',
            poi);
      }
    case PoiActivity.mystery:
      if (poi.mysteryClues.isNotEmpty) {
        context.push(AppRoutes.mystery(poi.id));
      } else {
        _showPending(
            context,
            'Mystery Clue',
            'Petunjuk tentang tokoh ini hanya boleh memakai informasi yang sudah diverifikasi '
                'museum (PRD R2, A05). Petunjuk akan muncul setelah validasi selesai.',
            poi);
      }
    case PoiActivity.mission:
      _showPending(context, 'Jejak Misi',
          'Jejak Misi (A02) belum tersedia pada versi ini.', poi);
  }
}

/// Galeri gambar POI (tombol "Galeri" di UI10).
void showPoiGallery(BuildContext context, Poi poi) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Galeri: ${poi.name}'),
            trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx)),
          ),
          SizedBox(
            height: 320,
            child: PageView(
              children: [
                for (final img in poi.mediaPaths
                    .where((p) => !p.startsWith('assets/audio')))
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: InteractiveViewer(
                        child: MediaImage(img, fit: BoxFit.contain)),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Geser untuk melihat, cubit untuk memperbesar',
                style: TextStyle(fontSize: 12, color: AppColors.grey)),
          ),
        ],
      ),
    ),
  );
}

/// Chronological events come from the curated timeline, not unique facts.
List<String> poiTimelineEntries(Poi poi) => [
      for (final section in poi.sections)
        if (section.title.toLowerCase().contains('linimasa'))
          ...section.body
              .split('\n')
              .map((line) => line.replaceFirst(RegExp(r'^-\s*'), '').trim())
              .where((line) => line.isNotEmpty),
    ];

void _showTimeline(BuildContext context, Poi poi) {
  final entries = poiTimelineEntries(poi);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.78,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text('Linimasa: ${poi.name}',
                  style: Theme.of(ctx).textTheme.titleMedium),
              trailing: IconButton(
                  tooltip: 'Tutup linimasa',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                  'Ikuti perjalanan sejarah dari atas ke bawah. Geser untuk melanjutkan.'),
            ),
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text('Linimasa koleksi ini belum tersedia.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final split = entry.indexOf(' — ');
                        final period = split < 0
                            ? 'Peristiwa ${index + 1}'
                            : entry.substring(0, split);
                        final story =
                            split < 0 ? entry : entry.substring(split + 3);
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 32,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 3,
                                      height: 20,
                                      color: index == 0
                                          ? Colors.transparent
                                          : AppColors.orange,
                                    ),
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: AppColors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: const [
                                          BoxShadow(
                                              color: AppColors.orangeLight,
                                              spreadRadius: 2)
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                        child: Container(
                                      width: 3,
                                      color: index == entries.length - 1
                                          ? Colors.transparent
                                          : AppColors.orange,
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.orangeLight),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(period,
                                          style: const TextStyle(
                                            color: AppColors.orange,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          )),
                                      const SizedBox(height: 8),
                                      Text(story,
                                          style: const TextStyle(height: 1.5)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showPending(BuildContext context, String title, String message, Poi poi) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.push(AppRoutes.quiz(poi.id));
          },
          child: const Text('Ikuti kuis'),
        ),
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
      ],
    ),
  );
}
