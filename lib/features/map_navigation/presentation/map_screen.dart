// lib/features/map_navigation/presentation/map_screen.dart
// UI05 Explore Map state 1 (di luar area POI) & UI06 state 2 (mendekati POI ±15 m).
// Denah 2D (gambar overlay) + marker 13 POI (11 baseline PRD v2 + 2 kandidat) (F01, F06). Wireframe: PRD Gambar 5.3.
// Marker oranye = sedang didekati/terpicu (status dari TriggerEngine).
// TODO(Farella/Firda): banner "Memindai beacon..." (state 1) / "Mendekati: <POI> ≈ 15 m" (state 2),
//   kartu "POI terdekat", lingkaran radius trigger 10 m, titik "Kamu".

import '../../../shared/widgets/jejak_app_bar.dart';
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
import 'museum_map_view.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pois = ref.watch(poisProvider);
    final selectedId = ref.watch(selectedMapPoiIdProvider);
    final proximity = ref.watch(poiProximityProvider).valueOrNull ?? const {};
    final visited = ref.watch(progressProvider).valueOrNull?.visitedPoiIds ??
        const <String>[];

    return Scaffold(
      appBar: JejakAppBar(title: const Text('Peta museum')),
      body: AsyncValueView<List<Poi>>(
        value: pois,
        data: (list) {
          Poi? selected;
          for (final p in list) {
            if (p.id == selectedId) selected = p;
          }
          return Column(
            children: [
              Expanded(
                  child: MuseumMapView(
                onTap: (_, __) =>
                    ref.read(selectedMapPoiIdProvider.notifier).state = null,
                children: [
                  OverlayImageLayer(
                    overlayImages: [
                      OverlayImage(
                        bounds: kMapBounds,
                        imageProvider:
                            const AssetImage(AppConstants.museumMapImage),
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
              )),
              if (selected != null)
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.38),
                  child: SingleChildScrollView(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                    child: _SelectedPoiSheet(poi: selected),
                  )),
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
    if (proximity == PoiProximity.triggered || selected) {
      color = AppColors.orange;
    }

    return GestureDetector(
      onTap: onTap,
      child: Center(
          child: Container(
        width: selected ? 36 : 32,
        height: selected ? 36 : 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: selected ? 3 : 2),
        ),
        child: Text(
          poi.id,
          style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold),
        ),
      )),
    );
  }
}

class _SelectedPoiSheet extends StatelessWidget {
  const _SelectedPoiSheet({required this.poi});

  final Poi poi;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${poi.id}: ${poi.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(poi.zone.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                onPressed: () => context.push(AppRoutes.poiDetail(poi.id)),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Detail'),
              )),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                onPressed: () => context.push(AppRoutes.navigateTo(poi.id)),
                icon: const Icon(Icons.directions_walk, size: 18),
                label: const Text('Arahkan'),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}
