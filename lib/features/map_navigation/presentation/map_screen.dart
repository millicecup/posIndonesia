// lib/features/map_navigation/presentation/map_screen.dart
// UI05 Explore Map state 1 (di luar area POI) & UI06 state 2 (mendekati POI ±15 m).
// Denah 2D (gambar overlay) + marker 13 POI (11 baseline PRD v2 + 2 kandidat) (F01, F06). Wireframe: PRD Gambar 5.3.
// Marker oranye = sedang didekati/terpicu (status dari TriggerEngine).
// TODO(Farella/Firda): banner "Memindai beacon..." (state 1) / "Mendekati: <POI> ≈ 15 m" (state 2),
//   kartu "POI terdekat", lingkaran radius trigger 10 m, titik "Kamu".

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/trigger_engine.dart';
import '../../../shared/widgets/async_value_view.dart';
import '../state/map_state.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(poisProvider);
    final selectedId = ref.watch(selectedMapPoiIdProvider);
    final proximity = ref.watch(poiProximityProvider).valueOrNull ?? const {};
    final visited =
        ref.watch(progressProvider).valueOrNull?.visitedPoiIds ?? const <String>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Peta Museum')),
      body: AsyncValueView<List<Poi>>(
        value: pois,
        data: (list) {
          Poi? selected;
          for (final p in list) {
            if (p.id == selectedId) selected = p;
          }
          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  crs: const CrsSimple(),
                  initialCameraFit: CameraFit.bounds(
                    bounds: kMapBounds,
                    padding: const EdgeInsets.all(12),
                  ),
                  minZoom: 1,
                  maxZoom: 6,
                  backgroundColor: AppColors.lightGrey,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: (_, __) =>
                      ref.read(selectedMapPoiIdProvider.notifier).state = null,
                ),
                children: [
                  OverlayImageLayer(
                    overlayImages: [
                      OverlayImage(
                        bounds: kMapBounds,
                        imageProvider: const AssetImage(AppConstants.museumMapImage),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (final poi in list)
                        Marker(
                          point: mapPositionToLatLng(poi.mapPosition),
                          width: 44,
                          height: 44,
                          child: _PoiMarker(
                            poi: poi,
                            selected: poi.id == selectedId,
                            visited: visited.contains(poi.id),
                            proximity: proximity[poi.id]?.proximity,
                            onTap: () => ref
                                .read(selectedMapPoiIdProvider.notifier)
                                .state = poi.id,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (selected != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _SelectedPoiSheet(poi: selected),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PoiMarker extends StatelessWidget {
  const _PoiMarker({
    required this.poi,
    required this.selected,
    required this.visited,
    required this.proximity,
    required this.onTap,
  });

  final Poi poi;
  final bool selected;
  final bool visited;
  final PoiProximity? proximity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.darkGrey;
    if (visited) color = AppColors.success;
    if (proximity == PoiProximity.approaching) color = AppColors.warning;
    if (proximity == PoiProximity.triggered || selected) color = AppColors.orange;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: selected ? 3 : 2),
        ),
        child: Text(
          poi.id,
          style: const TextStyle(
              color: AppColors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SelectedPoiSheet extends StatelessWidget {
  const _SelectedPoiSheet({required this.poi});

  final Poi poi;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${poi.id} · ${poi.name}',
                style: Theme.of(context).textTheme.titleMedium),
            Text(poi.zone.label, style: const TextStyle(color: AppColors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.navigateTo(poi.id)),
                    icon: const Icon(Icons.directions_walk),
                    label: const Text('Arahkan'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.poiDetail(poi.id)),
                    child: const Text('Detail'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
