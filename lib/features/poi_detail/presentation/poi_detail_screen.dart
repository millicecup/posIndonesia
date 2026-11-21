// lib/features/poi_detail/presentation/poi_detail_screen.dart
// UI10 POI Detail (state 4): ringkasan, 3-5 fakta penting bernomor, gambar, akses
// audio/galeri/foto/kuis (F03, F04), aktivitas khusus POI, dan "Selesai & ambil perangko"
// yang membuka UI13 (F08, PB13). Wireframe: PRD Gambar 5.4 tengah.

import '../../../shared/widgets/jejak_app_bar.dart';
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
      appBar: JejakAppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        leading: BackButton(onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.explore);
          }
        }),
      ),
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
              aspectRatio: 3 / 2,
              child: MediaImage(
                poi.coverImage!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
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
              Text('Ringkasan cerita', style: textTheme.titleMedium),
              if (poi.sections.isNotEmpty)
                for (final section in poi.sections
                    .where((s) => !s.title.toLowerCase().contains('linimasa')))
                  _SectionCard(
                      section: section, showTitle: section.title != poi.name)
              else
                Text(poi.shortDescription),
              const SizedBox(height: 16),
              if (poi.keyFacts.isNotEmpty)
                Text('Fakta unik', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final fact in poi.keyFacts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8, right: 10),
                        child: Icon(Icons.circle,
                            size: 5, color: AppColors.orange),
                      ),
                      Expanded(
                          child:
                              Text(fact, style: const TextStyle(height: 1.5))),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // Baris tombol Audio / Galeri / Foto / Kuis (wireframe UI10).
              Row(
                children: [
                  _MediaButton(
                    icon: Icons.play_arrow,
                    label: poi.hasRealAudio ? 'Mars' : 'Dengarkan cerita',
                    onPressed: () => listenToPoi(context, ref, poi),
                  ),
                  _MediaButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onPressed: () => showPoiGallery(context, poi),
                  ),
                  // Photo Studio untuk POI seragam (P04), langsung dibuka tanpa QR/lokasi.
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
                      'Tombol Dengarkan cerita membacakan cerita koleksi ini dengan pemandu suara.',
                      style: TextStyle(color: AppColors.grey, fontSize: 12)),
                ),
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
  const _SectionCard({required this.section, this.showTitle = true});
  final PoiSection section;
  final bool showTitle;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGrey, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle)
              Text(section.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            for (final p in section.paragraphs)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(p, style: const TextStyle(height: 1.4)),
              ),
            const SizedBox(height: 12),
            if (section.images.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < section.images.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      GestureDetector(
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
                          borderRadius: BorderRadius.circular(12),
                          child: MediaImage(section.images[i],
                              height: 220, fit: BoxFit.contain),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
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
              ? 'Lihat perangko yang sudah dikoleksi'
              : 'Selesai & ambil perangko'),
        ),
      ),
    );
  }
}
