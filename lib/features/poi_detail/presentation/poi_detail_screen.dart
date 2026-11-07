// lib/features/poi_detail/presentation/poi_detail_screen.dart
// UI10 POI Detail (state 4): ringkasan, 3-5 fakta penting, gambar, akses audio (F03, F04).
// Wireframe: PRD Gambar 5.4 tengah.
// TODO(Belinda): fakta bernomor (1,2,3), baris tombol Audio/Galeri/Foto, galeri PageView,
//   UI13 popup "Perangko Baru" setelah ambil perangko (PB13, Sprint 3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/category_chip.dart';
import '../../../shared/widgets/media_image.dart';
import '../state/poi_detail_state.dart';

class PoiDetailScreen extends ConsumerStatefulWidget {
  const PoiDetailScreen({super.key, required this.poiId});

  final String poiId;

  @override
  ConsumerState<PoiDetailScreen> createState() => _PoiDetailScreenState();
}

class _PoiDetailScreenState extends ConsumerState<PoiDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Membuka detail = POI dikunjungi (F07).
    Future.microtask(
        () => ref.read(progressProvider.notifier).markVisited(widget.poiId));
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(poiDetailProvider(widget.poiId));
    return Scaffold(
      appBar: AppBar(title: Text('Detail ${widget.poiId}')),
      body: AsyncValueView<PoiDetailData?>(
        value: detail,
        data: (data) => data == null
            ? const Center(child: Text('POI tidak ditemukan'))
            : _PoiDetailBody(data: data),
      ),
    );
  }
}

String _activityLabel(PoiActivity a) {
  switch (a) {
    case PoiActivity.timeline:
      return 'Timeline interaktif';
    case PoiActivity.gallery:
      return 'Galeri';
    case PoiActivity.quiz:
      return 'Kuis';
    case PoiActivity.mission:
      return 'Jejak Misi';
    case PoiActivity.minigame:
      return 'Mini-game kode pos';
    case PoiActivity.mystery:
      return 'Mystery Clue';
    case PoiActivity.photoStudio:
      return 'Coba Photo Studio';
    case PoiActivity.stampVisualization:
      return 'Lihat 5 tahap pembuatan prangko';
    case PoiActivity.postmark:
      return 'Digital Postmark';
  }
}

class _PoiDetailBody extends ConsumerWidget {
  const _PoiDetailBody({required this.data});

  final PoiDetailData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = data.poi;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      children: [
        if (poi.coverImage != null)
          AspectRatio(
            aspectRatio: 3 / 2,
            child: MediaImage(poi.coverImage!),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(poi.name, style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Row(children: [
                CategoryChip(label: poi.category.label, dense: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(poi.zone.label,
                      style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                ),
              ]),
              if (!poi.contentValidated)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Konten masih menunggu validasi museum.',
                      style: TextStyle(color: AppColors.warning, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              Text(poi.shortDescription),
              const SizedBox(height: 16),
              Text('Fakta Penting', style: textTheme.titleMedium),
              const SizedBox(height: 4),
              for (final fact in poi.keyFacts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: AppColors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(fact)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              if (poi.hasAudio)
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.audioPlayer(poi.id)),
                  icon: const Icon(Icons.headphones),
                  label: Text(poi.id == 'P05'
                      ? 'Putar Mars Pos Indonesia'
                      : 'Dengarkan Narasi'),
                )
              else
                const Text('Narasi audio belum tersedia.',
                    style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: data.stampCollected
                    ? null
                    : () async {
                        final isNew = await ref
                            .read(progressProvider.notifier)
                            .collectStamp(poi.stamp.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isNew
                                ? 'Perangko "${poi.stamp.title}" masuk album!'
                                : 'Perangko sudah ada di album'),
                          ));
                        }
                      },
                icon: const Icon(Icons.local_post_office),
                label: Text(data.stampCollected
                    ? 'Perangko sudah dikoleksi'
                    : 'Selesai & ambil perangko'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.navigateTo(poi.id)),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Arahkan ke lokasi ini'),
              ),
              for (final activity in poi.activities) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  // TODO(Sprint 3-4): buka aktivitas (Photo Studio, kuis, mini-game, dll).
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${_activityLabel(activity)} tersedia di sprint berikutnya')),
                  ),
                  icon: const Icon(Icons.extension),
                  label: Text(_activityLabel(activity)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
