import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jejakpos/app/theme.dart';
import 'package:jejakpos/features/stamp_making/presentation/stamp_making_screen.dart';

void main() {
  for (final direct in [true, false]) {
    testWidgets('Finish returns to P05 detail (direct: $direct)',
        (tester) async {
      final router = GoRouter(
          initialLocation: direct ? '/stamp-making/P05' : '/poi/P05',
          routes: [
            GoRoute(
                path: '/poi/:id',
                builder: (context, state) => Scaffold(
                    body: TextButton(
                        onPressed: () => context.push('/stamp-making/P05'),
                        child: const Text('Detail P05')))),
            GoRoute(
                path: '/stamp-making/:id',
                builder: (context, state) =>
                    const StampMakingScreen(poiId: 'P05')),
          ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      if (!direct) {
        await tester.tap(find.text('Detail P05'));
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Lanjut'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Detail P05'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/poi/P05');
    });
  }
  test('curated galleries retain one reference per selected photograph', () {
    final raw = jsonDecode(File('assets/data/pois.json').readAsStringSync());
    final pois = raw is List ? raw : raw['pois'] as List;
    for (final entry
        in {'P01': 4, 'P03': 2, 'P04': 10, 'P05': 2, 'P08': 5}.entries) {
      final poi = pois.firstWhere((p) => p['id'] == entry.key);
      final images = poi['images'] as List;
      expect(images.length, entry.value, reason: entry.key);
      expect(images.toSet().length, images.length);
      for (final section in poi['sections'] as List) {
        final pictures = section['images'] as List? ?? [];
        expect(pictures.toSet().length, pictures.length);
      }
    }
    expect(stampMakingSteps.map((s) => s.image).toSet().length, 5);
    final soeharto = pois.firstWhere((p) => p['id'] == 'P08');
    expect(soeharto['sections'][1]['images'], [
      'assets/images/pois/p08_09.jpg',
      'assets/images/pois/p08_10.jpg',
    ]);
    expect(soeharto['sections'][0]['images'],
        contains('assets/images/pois/p08_06.jpg'));
    for (final step in stampMakingSteps) {
      expect(File('assets/images/stamp_making/${step.image}').lengthSync(),
          greaterThan(1000));
    }
  });

  testWidgets(
      'all five stages have their own image and explanation on small screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light, home: const StampMakingScreen(poiId: 'P05')));
    for (var i = 0; i < 5; i++) {
      await tester.pumpAndSettle();
      expect(find.text(stampMakingSteps[i].title), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as AssetImage).assetName,
          endsWith(stampMakingSteps[i].image));
      expect(tester.takeException(), isNull);
      if (i < 4) await tester.tap(find.text('Lanjut'));
    }
    expect(find.text('Selesai'), findsOneWidget);
    await tester.tap(find.text('Sebelumnya'));
    await tester.pumpAndSettle();
    expect(find.text('Perforasi'), findsOneWidget);
  });
}
