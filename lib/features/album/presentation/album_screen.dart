// lib/features/album/presentation/album_screen.dart
// UI14 Album Perangko Digital (tab Album): koleksi tanpa duplikasi, progres, slot terkunci,
// ketuk perangko untuk melihat cerita di baliknya (F08, PB13). Wireframe: PRD Gambar 5.5 tengah.

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
      appBar: AppBar(title: const Text('Album Perangko')),
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
                    border: Border.all(color: AppColors.lightGrey, width: 2),
                    borderRadius: BorderRadius.circular(12),
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
                              color: AppColors.darkGrey,
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
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: pois.length,
                  itemBuilder: (_, i) {
                    final poi = pois[i];
                    final has = p.hasStamp(poi.stamp.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => has
                          ? _showStory(context, poi)
                          : _showLocked(context, poi),
                      child: StampFrame(
                        image: poi.stamp.image,
                        random: poi.stamp.isRandom,
                        locked: !has,
                        size: 92,
                        label: has ? '${poi.id}: ${poi.stamp.title}' : poi.id,
                      ),
                    );
                  },
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
              StampFrame(image: poi.stamp.image, random: poi.stamp.isRandom, size: 110),
              const SizedBox(height: 12),
              Text(poi.stamp.title, style: Theme.of(ctx).textTheme.titleMedium),
              Text('${poi.id}: ${poi.name}', style: const TextStyle(color: AppColors.grey)),
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
        content: Text('Perangko ${poi.id} terkunci. Kunjungi "${poi.name}" untuk membukanya.'),
        action: SnackBarAction(
            label: 'ARAH', onPressed: () => context.push(AppRoutes.navigateTo(poi.id))),
      ));
  }
}
