// lib/features/album/presentation/album_screen.dart
// UI14 Album Perangko Digital (tab Album): koleksi tanpa duplikasi, progres, slot terkunci,
// ketuk perangko untuk melihat cerita di baliknya (F08, PB13). Wireframe: PRD Gambar 5.5 tengah.

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/stamp_unlocked_dialog.dart';

class AlbumScreen extends ConsumerWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final pois = ref.watch(poisProvider).valueOrNull ?? const <Poi>[];

    return Scaffold(
      appBar: JejakAppBar(title: const Text('Album Perangko')),
      body: AsyncValueView<VisitProgress>(
        value: progress,
        data: (p) {
          final owned = pois.where((poi) => p.hasStamp(poi.stamp.id)).length;
          final ratio = pois.isEmpty ? 0.0 : owned / pois.length;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border.all(color: AppColors.lightGrey),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$owned / ${pois.length} terkumpul',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: ratio,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              color: AppColors.teal,
                              backgroundColor: AppColors.lightGrey,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(label: Text('${(ratio * 100).round()}%')),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 600 ? 3 : 2;
                    const gap = 16.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    final stampSize = (width - 24).clamp(96.0, 170.0);
                    return Wrap(
                      spacing: gap,
                      runSpacing: 20,
                      children: [
                        for (final poi in pois)
                          SizedBox(
                            width: width,
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => p.hasStamp(poi.stamp.id)
                                    ? _showStory(context, poi)
                                    : _showLocked(context, poi),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 8),
                                  child: StampFrame(
                                    image: poi.stamp.image,
                                    random: poi.stamp.isRandom,
                                    locked: !p.hasStamp(poi.stamp.id),
                                    size: stampSize,
                                    label: p.hasStamp(poi.stamp.id)
                                        ? '${poi.id}: ${poi.stamp.title}'
                                        : poi.id,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Ketuk perangko untuk melihat cerita di baliknya',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.grey)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStory(BuildContext context, Poi poi) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StampFrame(
                  image: poi.stamp.image,
                  random: poi.stamp.isRandom,
                  size: 110),
              const SizedBox(height: 12),
              Text(poi.stamp.title, style: Theme.of(ctx).textTheme.titleMedium),
              Text('${poi.id}: ${poi.name}',
                  style: const TextStyle(color: AppColors.grey)),
              const SizedBox(height: 8),
              Text(poi.stamp.trivia, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push(AppRoutes.poiDetail(poi.id));
                },
                child: const Text('Buka koleksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocked(BuildContext context, Poi poi) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
            'Perangko ${poi.id} terkunci. Kunjungi "${poi.name}" untuk membukanya.'),
        action: SnackBarAction(
            label: 'ARAH',
            onPressed: () => context.push(AppRoutes.navigateTo(poi.id))),
      ));
  }
}
