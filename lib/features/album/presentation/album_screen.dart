// lib/features/album/presentation/album_screen.dart
// UI14 Album Perangko Digital (tab Album): koleksi tanpa duplikasi + slot terkunci (F08).
// Wireframe: PRD Gambar 5.5 tengah. Implementasi penuh = PB13 (Sprint 3).
// TODO(Sprint 3): header "4 / 13 terkumpul", slot "?" untuk yang belum, ketuk -> trivia.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';

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
        data: (p) => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: pois.length,
          itemBuilder: (_, i) {
            final stamp = pois[i].stamp;
            final owned = p.hasStamp(stamp.id);
            return Opacity(
              opacity: owned ? 1 : 0.3,
              child: Column(
                children: [
                  Expanded(
                    child: stamp.image != null
                        ? Image.asset(stamp.image!, fit: BoxFit.contain)
                        : const Icon(Icons.local_post_office, size: 48),
                  ),
                  Text(
                    owned ? stamp.title : 'Belum dikoleksi',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.darkGrey),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
