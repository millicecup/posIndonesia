// lib/features/visual_tour_guide/presentation/visual_tour_guide_screen.dart
// UI09 Visual Tour Guide 2D: karakter pemandu (placeholder) + rekomendasi POI berikutnya.
// TODO(Farella): ilustrasi pemandu 2D (bukan avatar 3D - non-goal), balon dialog.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/poi_card.dart';
import '../../../shared/widgets/progress_badge.dart';
import '../state/tour_state.dart';

class VisualTourGuideScreen extends ConsumerWidget {
  const VisualTourGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tour = ref.watch(tourStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pemandu Tur')),
      body: AsyncValueView<TourState>(
        value: tour,
        data: (t) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Center(
              child: ProgressBadge(
                  visited: t.progress.visitedCount, total: t.progress.totalPois),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.orangeLight,
                    child: Icon(Icons.local_post_office, size: 36, color: AppColors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.lightGrey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(t.next == null
                          ? 'Hebat! Kamu sudah mengunjungi semua koleksi.'
                          : 'Ayo lanjut ke ${t.next!.name} di ${t.next!.zone.description}!'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (t.next != null) ...[
              PoiCard(
                poi: t.next!,
                onTap: () => context.push(AppRoutes.poiDetail(t.next!.id)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.navigateTo(t.next!.id)),
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('Tunjukkan arah'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
