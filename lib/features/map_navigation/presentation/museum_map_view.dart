import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../app/theme.dart';
import '../state/map_state.dart';

/// Shared floor-plan camera: fit the whole image and allow at most 4x zoom.
class MuseumMapView extends StatefulWidget {
  const MuseumMapView({super.key, required this.children, this.onTap});

  final List<Widget> children;
  final TapCallback? onTap;

  @override
  State<MuseumMapView> createState() => _MuseumMapViewState();
}

class _MuseumMapViewState extends State<MuseumMapView> {
  final _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final scale = math.min(
            math.max(1, constraints.maxWidth - 24) / kMapUnitWidth,
            math.max(1, constraints.maxHeight - 24) / kMapUnitHeight,
          );
          // flutter_map 7 uses 256 * 2^zoom even for CrsSimple.
          // A floor plan in these units needs negative zoom on phone screens.
          final fitZoom = const CrsSimple().zoom(scale);
          final maxZoom = fitZoom + 2;

          void reset() => _controller.fitCamera(CameraFit.bounds(
                bounds: kMapBounds,
                padding: const EdgeInsets.all(12),
                minZoom: fitZoom,
                maxZoom: maxZoom,
              ));

          void zoom(double delta) => _controller.move(
                _controller.camera.center,
                (_controller.camera.zoom + delta).clamp(fitZoom, maxZoom),
              );

          return Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  crs: const CrsSimple(),
                  initialCameraFit: CameraFit.bounds(
                    bounds: kMapBounds,
                    padding: const EdgeInsets.all(12),
                    minZoom: fitZoom,
                    maxZoom: maxZoom,
                  ),
                  minZoom: fitZoom,
                  maxZoom: maxZoom,
                  backgroundColor: AppColors.lightGrey,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.pinchZoom,
                  ),
                  onTap: widget.onTap,
                ),
                children: widget.children,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Perbesar peta',
                        onPressed: () => zoom(0.5),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Perkecil peta',
                        onPressed: () => zoom(-0.5),
                        icon: const Icon(Icons.remove),
                      ),
                      IconButton(
                        tooltip: 'Tampilkan seluruh denah',
                        onPressed: reset,
                        icon: const Icon(Icons.fit_screen),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
}
