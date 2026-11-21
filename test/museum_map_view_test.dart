import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/features/map_navigation/presentation/museum_map_view.dart';
import 'package:jejakpos/features/map_navigation/state/map_state.dart';

void main() {
  testWidgets('map refits when the selected POI panel reduces viewport height',
      (tester) async {
    Widget view(double height) => MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 360,
                    height: height,
                    child: const MuseumMapView(children: [])))));
    await tester.pumpWidget(view(560));
    await tester.pumpAndSettle();
    await tester.pumpWidget(view(260));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final scale = const CrsSimple().scale(map.mapController!.camera.zoom);
    expect(kMapUnitHeight * scale, lessThanOrEqualTo(236.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone camera fits the denah and zoom controls can reset it',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            height: 560,
            child: MuseumMapView(children: []),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    final controller = map.mapController!;
    final initialZoom = controller.camera.zoom;
    expect(initialZoom, lessThan(0));
    final scale = const CrsSimple().scale(initialZoom);
    expect(kMapUnitWidth * scale, lessThanOrEqualTo(336.001));
    expect(kMapUnitHeight * scale, lessThanOrEqualTo(536.001));

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byTooltip('Perbesar peta'));
      await tester.pump();
    }
    expect(controller.camera.zoom, closeTo(initialZoom + 2, 0.001));
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.byTooltip('Perkecil peta'));
      await tester.pump();
    }
    expect(controller.camera.zoom, closeTo(initialZoom, 0.001));
    await tester.tap(find.byTooltip('Perbesar peta'));
    await tester.pump();
    await tester.tap(find.byTooltip('Tampilkan seluruh denah'));
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, closeTo(initialZoom, 0.001));

    final center = tester.getCenter(find.byType(FlutterMap));
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(controller.camera.zoom, closeTo(initialZoom, 0.001));
    expect(controller.camera.rotation, 0);
  });
}
