// lib/features/poi_detail/presentation/poi_detail_screen.dart
// UI10 POI Detail (state 4): ringkasan, 3-5 fakta penting bernomor, gambar, akses
// audio/galeri/foto/kuis (F03, F04), aktivitas khusus POI, dan "Selesai & ambil perangko"
// yang membuka UI13 (F08, PB13). Wireframe: PRD Gambar 5.4 tengah.

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
import '../../../shared/widgets/stamp_unlocked_dialog.dart';
import '../state/poi_detail_state.dart';
import '../../voice_guide/presentation/listen_to_poi.dart';
import '../../voice_guide/presentation/voice_guide_bar.dart';
import 'poi_activity_launcher.dart';

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
    final title = detail.valueOrNull?.poi.name ?? 'Detail ${widget.poiId}';
    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: AsyncValueView<PoiDetailData?>(
        value: detail,
        data: (data) => data == null
            ? const Center(child: Text('POI tidak ditemukan'))
            : _PoiDetailBody(data: data),
      ),
      bottomNavigationBar: detail.valueOrNull == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const VoiceGuideBar(),
                _CollectStampBar(data: detail.valueOrNull!),
              ],
            ),
    );
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
          GestureDetector(
            onTap: () => showPoiGallery(context, poi),
            child: AspectRatio(
                aspectRatio: 3 / 2, child: MediaImage(poi.coverImage!)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(poi.name, style: textTheme.titleLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  CategoryChip(label: poi.category.label, dense: true),
                  CategoryChip(label: 'Zona ${poi.zone.code}', dense: true),
                  if (data.visited)
                    const Icon(Icons.check_circle,
                        size: 18, color: AppColors.success),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(poi.zone.description,
                    style:
                        const TextStyle(color: AppColors.grey, fontSize: 12)),
              ),
              if (!poi.contentValidated)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Konten masih menunggu validasi museum.',
                      style: TextStyle(color: AppColors.warning, fontSize: 12)),
                ),
              const SizedBox(height: 12),
              Text(poi.shortDescription),
              const SizedBox(height: 16),
              Text('Fakta penting', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < poi.keyFacts.length; i++)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGrey, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(poi.keyFacts[i])),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Baris tombol Audio / Galeri / Foto / Kuis (wireframe UI10).
              Row(
                children: [
                  _MediaButton(
                    icon: Icons.play_arrow,
                    label: poi.hasRealAudio ? 'Mars' : 'Dengar',
                    onPressed: () => listenToPoi(context, ref, poi),
                  ),
                  _MediaButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onPressed: () => showPoiGallery(context, poi),
                  ),
                  // Photo Studio hanya untuk POI seragam (P04), dibuka lewat launcher
                  // yang memeriksa apakah pengunjung sudah terdeteksi di area tersebut.
                  if (poi.activities.contains(PoiActivity.photoStudio))
                    _MediaButton(
                      icon: Icons.camera_alt_outlined,
                      label: 'Foto',
                      onPressed: () => openPoiActivity(
                          context, poi, PoiActivity.photoStudio),
                    ),
                  _MediaButton(
                    icon: Icons.quiz_outlined,
                    label: 'Kuis',
                    onPressed: () => context.push(AppRoutes.quiz(poi.id)),
                  ),
                ],
              ),
              if (!poi.hasRealAudio)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                      'Tombol Dengar membacakan cerita koleksi ini dengan pemandu suara.',
                      style: TextStyle(color: AppColors.grey, fontSize: 12)),
                ),
              if (poi.sections.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Cerita lengkap', style: textTheme.titleMedium),
                for (final section in poi.sections)
                  _SectionCard(section: section),
              ],
              if (poi.activities.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Aktivitas di koleksi ini', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                for (final activity in poi.activities)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44)),
                      onPressed: () => openPoiActivity(context, poi, activity),
                      icon: Icon(poiActivityIcon(activity)),
                      label: Text(poiActivityLabel(activity)),
                    ),
                  ),
              ],
              if (poi.contentSource != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Sumber konten: ${poi.contentSource}',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.grey)),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => context.push(AppRoutes.navigateTo(poi.id)),
                icon: const Icon(Icons.directions_walk),
                label: const Text('Arahkan ke lokasi ini'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Satu bagian cerita (mis. "Lencana" di P04) dengan foto yang bisa diperbesar.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final PoiSection section;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGrey, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(section.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.images.isNotEmpty)
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: section.images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (ctx) => Dialog(
                          insetPadding: const EdgeInsets.all(12),
                          child: InteractiveViewer(
                              child: MediaImage(section.images[i],
                                  fit: BoxFit.contain)),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: MediaImage(section.images[i])),
                      ),
                    ),
                  ),
                ),
              for (final p in section.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(p, style: const TextStyle(height: 1.4)),
                ),
            ],
          ),
        ),
      );
}

class _MediaButton extends StatelessWidget {
  const _MediaButton({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: onPressed,
            child: Column(
              children: [
                Icon(icon, size: 20),
                Text(label, style: const TextStyle(fontSize: 12))
              ],
            ),
          ),
        ),
      );
}

class _CollectStampBar extends ConsumerWidget {
  const _CollectStampBar({required this.data});
  final PoiDetailData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = data.poi;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton.icon(
          onPressed: () async {
            if (poi.stamp.isRandom) {
              await ref
                  .read(activityStatsProvider.notifier)
                  .ensureRandomStampSeed();
            }
            final isNew = await ref
                .read(progressProvider.notifier)
                .collectStamp(poi.stamp.id);
            if (context.mounted) {
              await showStampUnlockedDialog(context, poi: poi, isNew: isNew);
            }
          },
          icon: Icon(
              data.stampCollected ? Icons.verified : Icons.local_post_office),
          label: Text(data.stampCollected
              ? 'Perangko sudah dikoleksi · lihat lagi'
              : 'Selesai & ambil perangko'),
        ),
      ),
    );
  }
}
