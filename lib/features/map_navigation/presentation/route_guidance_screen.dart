// lib/features/map_navigation/presentation/route_guidance_screen.dart
// UI07 Navigasi ke POI: rute visual di denah + petunjuk teks (F06). Wireframe: PRD Gambar 5.2.
// Bukan navigasi turn-by-turn kompleks (NG02).
// TODO(Firda): daftar langkah teks per POI ("1. Lurus ke lorong utama ...") setelah denah resmi ada,
//   tombol "Ganti tujuan" & "Mulai".

import '../../../shared/widgets/jejak_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/haversine.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../state/map_state.dart';
import 'museum_map_view.dart';

class RouteGuidanceScreen extends ConsumerWidget {
  const RouteGuidanceScreen({super.key, required this.poiId});

  final String poiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final target = ref.watch(poiByIdProvider(poiId));
    final position = ref.watch(positionStreamProvider).valueOrNull;
    final progress = ref.watch(progressProvider).valueOrNull;
    final pois = ref.watch(poisProvider).valueOrNull ?? const <Poi>[];

    return Scaffold(
      appBar: JejakAppBar(title: Text('Menuju $poiId')),
      body: AsyncValueView<Poi?>(
        value: target,
        data: (poi) {
          if (poi == null) {
            return const Center(child: Text('POI tidak ditemukan'));
          }

          // Titik awal di denah: POI terakhir dikunjungi, atau pintu masuk (P11 Stempel Museum; PRD v1: P12).
          final lastId = (progress?.visitedPoiIds.isNotEmpty ?? false)
              ? progress!.visitedPoiIds.last
              : 'P11';
          Poi? from;
          for (final p in pois) {
            if (p.id == lastId) from = p;
          }

          String instruction;
          if (position != null && poi.hasCoordinates) {
            final d = haversineDistanceMeters(position.latitude,
                position.longitude, poi.latitude!, poi.longitude!);
            final b = bearingDegrees(position.latitude, position.longitude,
                poi.latitude!, poi.longitude!);
            instruction = d <= poi.triggerRule.triggerRadiusMeters
                ? 'Kamu sudah berada di area ${poi.id}.'
                : 'Berjalan ±${d.toStringAsFixed(0)} m ke arah ${compassLabel(b)}.';
          } else {
            instruction = 'Posisi belum terbaca. Ikuti garis oranye di denah '
                '${from != null ? 'dari ${from.id} ' : ''}menuju ${poi.id}.';
          }

          return Column(
            children: [
              Expanded(
                child: MuseumMapView(
                  children: [
                    OverlayImageLayer(overlayImages: [
                      OverlayImage(
                        bounds: kMapBounds,
                        imageProvider:
                            const AssetImage(AppConstants.museumMapImage),
                      ),
                    ]),
                    if (from != null && from.id != poi.id)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: [
                            mapPositionToLatLng(from.mapPosition),
                            mapPositionToLatLng(poi.mapPosition),
                          ],
                          strokeWidth: 4,
                          color: AppColors.orange,
                        ),
                      ]),
                    MarkerLayer(markers: [
                      if (from != null && from.id != poi.id)
                        Marker(
                          point: mapPositionToLatLng(from.mapPosition),
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.person_pin_circle,
                              color: AppColors.darkGrey, size: 36),
                        ),
                      Marker(
                        point: mapPositionToLatLng(poi.mapPosition),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.place,
                            color: AppColors.orange, size: 40),
                      ),
                    ]),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${poi.id}: ${poi.name}',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(poi.zone.label,
                        style: const TextStyle(color: AppColors.grey)),
                    const SizedBox(height: 8),
                    Text(instruction),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          context.push(AppRoutes.poiDetail(poi.id)),
                      child: const Text('Lihat detail'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
