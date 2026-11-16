import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jejakpos/data/models/poi.dart';
import 'package:jejakpos/features/photo_studio/presentation/photo_studio_screen.dart';
import 'package:jejakpos/features/photo_studio/widgets/uniform_overlay.dart';
import 'package:jejakpos/features/poi_detail/presentation/poi_activity_launcher.dart';

import 'helpers/test_data.dart';

void main() {
  testWidgets('Photo Studio opens without a location trigger or QR',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final poi = loadDataset().firstWhere(
      (poi) => poi.activities.contains(PoiActivity.photoStudio),
    );
    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      openPoiActivity(context, poi, PoiActivity.photoStudio),
                  child: const Text('Coba Photo Studio'),
                ),
              )),
      GoRoute(
          path: '/photo-studio',
          builder: (_, state) =>
              PhotoStudioScreen(poiId: state.uri.queryParameters['poi'])),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)));
    await tester.tap(find.text('Coba Photo Studio'));
    await tester.pumpAndSettle();
    expect(find.text('Photo Studio'), findsOneWidget);
    expect(find.text('Pindai QR'), findsNothing);
    expect(find.text('Galeri'), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    await tester.tap(find.text('Hijau'));
    await tester.pumpAndSettle();
    expect(find.text('Seragam Hijau'), findsOneWidget);
    expect(tester.widget<UniformBody>(find.byType(UniformBody).first).template,
        UniformTemplate.hijau);
    expect(tester.widget<UniformCap>(find.byType(UniformCap).first).template,
        UniformTemplate.hijau);
  });

  test('every colour has matching original PNG assets and aspect ratios', () {
    for (final template in UniformTemplate.values) {
      for (final pair in [
        (template.bodyAsset, template.bodyAspect),
        (template.capAsset, template.capAspect),
      ]) {
        final bytes = File(pair.$1).readAsBytesSync();
        final header = bytes.buffer.asByteData();
        final width = header.getUint32(16);
        final height = header.getUint32(20);
        expect(height / width, closeTo(pair.$2, 0.00001));
      }
    }
  });
}
