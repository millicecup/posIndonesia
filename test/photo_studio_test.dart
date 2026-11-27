import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jejakpos/data/models/poi.dart';
import 'package:jejakpos/core/utils/app_logger.dart';
import 'package:jejakpos/features/photo_studio/presentation/photo_studio_screen.dart';
import 'package:jejakpos/features/photo_studio/widgets/uniform_overlay.dart';
import 'package:jejakpos/features/photo_studio/studio_camera.dart';
import 'package:jejakpos/features/photo_studio/studio_gallery.dart';
import 'package:jejakpos/features/poi_detail/presentation/poi_activity_launcher.dart';
import 'package:jejakpos/services/permission_service.dart';

import 'helpers/test_data.dart';

class FakeStudioCamera implements StudioCamera {
  final Uint8List photo =
      File('assets/images/onboarding.png').readAsBytesSync();
  int shots = 0;
  bool disposed = false;
  @override
  bool get mirrorPhoto => true;
  @override
  double get aspectRatio => 9 / 16;
  @override
  Future<void> initialize() async {}
  @override
  Widget preview() =>
      const ColoredBox(key: Key('live-preview'), color: Colors.blue);
  @override
  Future<Uint8List> takePhoto() async {
    shots++;
    return photo;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeCameraPermission implements CameraPermissionGate {
  FakeCameraPermission([this.current = AppPermissionStatus.granted]);
  AppPermissionStatus current;
  AppPermissionStatus? afterRequest;
  int requests = 0;
  int settingsOpened = 0;
  @override
  Future<AppPermissionStatus> status() async => current;
  @override
  Future<AppPermissionStatus> request() async {
    requests++;
    if (afterRequest != null) current = afterRequest!;
    return current;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}

class FakeStudioGallery extends StudioGallery {
  bool fail = false;
  Uint8List? saved;
  @override
  Future<void> save(Uint8List png, String name) async {
    if (fail) throw StateError('Penyimpanan gagal');
    saved = png;
  }
}

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
    await tester.pumpWidget(ProviderScope(overrides: [
      studioCameraFactoryProvider.overrideWithValue(FakeStudioCamera.new),
      studioCameraPermissionProvider.overrideWithValue(FakeCameraPermission()),
    ], child: MaterialApp.router(routerConfig: router)));
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

  testWidgets('live overlay, shutter, editor and gallery save confirmation',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final camera = FakeStudioCamera();
    final gallery = FakeStudioGallery()..fail = true;
    await tester.pumpWidget(ProviderScope(overrides: [
      studioCameraFactoryProvider.overrideWithValue(() => camera),
      studioCameraPermissionProvider.overrideWithValue(FakeCameraPermission()),
      studioGalleryProvider.overrideWithValue(gallery),
    ], child: const MaterialApp(home: PhotoStudioScreen(poiId: 'P04'))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('live-preview')), findsOneWidget);
    expect(find.byType(UniformBody), findsWidgets);
    expect(find.byType(UniformCap), findsWidgets);
    await tester.runAsync(() => precacheImage(
          MemoryImage(camera.photo),
          tester.element(find.byType(PhotoStudioScreen)),
        ));
    await tester.tap(find.byTooltip('Jepret foto'));
    await tester.pumpAndSettle();
    expect(camera.shots, 1);
    expect(camera.disposed, isTrue);
    expect(find.byKey(const Key('live-preview')), findsNothing);
    await tester.tap(find.text('Hijau'));
    await tester.pumpAndSettle();
    final resultButton = tester.widget<FilledButton>(find.ancestor(
      of: find.text('Lihat hasil'),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    ));
    expect(resultButton.onPressed, isNotNull);
    await tester.tap(find.text('Lihat hasil'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 20 && find.text('Hasil Foto').evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text('Hasil Foto'), findsOneWidget,
        reason: AppLogger.entries.toString());
    await tester.tap(find.text('Simpan ke galeri'));
    await tester.pumpAndSettle();
    expect(find.text('Tersimpan'), findsNothing);
    expect(gallery.saved, isNull);
    gallery.fail = false;
    await tester.tap(find.text('Simpan ke galeri'));
    await tester.pumpAndSettle();
    expect(find.text('Photo Studio'), findsOneWidget);
    expect(find.text('Hasil Foto'), findsNothing);
    expect(find.text('Foto sudah tersimpan di galeri HP.'), findsOneWidget);
    expect(find.text('Buka galeri'), findsNothing);
    expect(gallery.saved!.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lihat hasil'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 20 && find.text('Hasil Foto').evaluate().isEmpty; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(find.text('Simpan ke galeri'), findsOneWidget);
    expect(find.text('Tersimpan'), findsNothing);
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
