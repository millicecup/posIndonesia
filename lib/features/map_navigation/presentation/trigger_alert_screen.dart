// lib/features/map_navigation/presentation/trigger_alert_screen.dart
// UI08 POI Trigger Notification (state 3): muncul sekali per kunjungan saat POI terpicu (F02, F07).
// Wireframe PRD Gambar 5.3 kanan: "TRIGGER AKTIF" + Lihat Info / Dengarkan / Nanti.
// TODO(Firda): jadikan bottom sheet di atas peta sesuai wireframe; ilustrasi petugas pos.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../../../shared/widgets/media_image.dart';

class TriggerAlertScreen extends ConsumerWidget {
  const TriggerAlertScreen({super.key, required this.poiId});

  final String poiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poi = ref.watch(poiByIdProvider(poiId));
    return Scaffold(
      appBar: AppBar(title: const Text('Koleksi Terdeteksi')),
      body: AsyncValueView<Poi?>(
        value: poi,
        data: (p) => p == null
            ? const Center(child: Text('POI tidak ditemukan'))
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('TRIGGER AKTIF',
                          style: TextStyle(
                              color: AppColors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Text('Kamu berada di zona ${p.zone.code}',
                        style: Theme.of(context).textTheme.bodyLarge),
                    Text(p.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text(p.zone.label, style: const TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 16),
                    if (p.coverImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: MediaImage(p.coverImage!, height: 180),
                      ),
                    const SizedBox(height: 16),
                    Text(p.systemResponse, textAlign: TextAlign.center),
                    const Text('Muncul sekali per kunjungan',
                        style: TextStyle(fontSize: 12, color: AppColors.grey)),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => context.pushReplacement(AppRoutes.poiDetail(p.id)),
                      child: const Text('Lihat Info'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: p.hasAudio
                                ? () => context.pushReplacement(AppRoutes.audioPlayer(p.id))
                                : null,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Dengarkan'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Nanti'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
