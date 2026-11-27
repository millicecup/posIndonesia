// test/defect_retest_test.dart
// Retest semua defek dari "Rangkuman Defek dan Retest" (DF-01 s.d. DF-11).
// Tiap grup memuat skenario utama + skenario negatif/batas.

import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart' show CameraException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jejakpos/app/app.dart';
import 'package:jejakpos/app/theme.dart';
import 'package:jejakpos/core/constants/app_constants.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/features/home_explorer/widgets/explore_tutorial.dart';
import 'package:jejakpos/features/map_navigation/presentation/museum_welcome_dialog.dart';
import 'package:jejakpos/features/mystery_clue/presentation/mystery_clue_screen.dart';
import 'package:jejakpos/features/photo_studio/presentation/photo_studio_screen.dart';
import 'package:jejakpos/features/photo_studio/studio_camera.dart';
import 'package:jejakpos/features/poi_detail/presentation/poi_detail_screen.dart';
import 'package:jejakpos/features/progress/presentation/progress_screen.dart';
import 'package:jejakpos/features/qr_scanner/presentation/qr_scanner_screen.dart';
import 'package:jejakpos/features/vision_tour/presentation/vision_tour_screen.dart';
import 'package:jejakpos/features/vision_tour/state/vision_tour_controller.dart';
import 'package:jejakpos/features/visit_summary/presentation/visit_summary_screen.dart';
import 'package:jejakpos/features/visit_summary/widgets/passport_postmark_card.dart';
import 'package:jejakpos/features/visual_tour_guide/presentation/visual_tour_guide_screen.dart';
import 'package:jejakpos/features/voice_guide/presentation/voice_guide_bar.dart';
import 'package:jejakpos/features/voice_guide/state/voice_guide_controller.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/services/narration_service.dart';
import 'package:jejakpos/services/permission_service.dart';
import 'package:jejakpos/services/trigger_engine.dart';
import 'package:jejakpos/services/vision/sift_recognizer.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/retest_fakes.dart';
import 'helpers/test_data.dart';
import 'photo_studio_test.dart' show FakeStudioCamera, FakeCameraPermission;

// Posisi dari bukti DF-01: 82 m dari pusat museum (di dalam geofence 150 m),
// jauh dari semua POI.
UserPosition _pos(double lat, double lng, {double accuracy = 1}) =>
    UserPosition(
        latitude: lat,
        longitude: lng,
        accuracyMeters: accuracy,
        timestamp: DateTime.now());
final _insideMuseum = _pos(-6.902054, 107.619743);
final _farAway = _pos(-6.879022, 107.619729, accuracy: 5); // ~2,6 km

class _NativeStub extends SiftRecognizer {
  String status = 'unknown';
  String? id;
  @override
  Future<int> initialize() async => 70;
  @override
  Future<Map<String, dynamic>> recognize(
          {required Uint8List bytes,
          required int width,
          required int height,
          required int stride,
          required int pixelStride,
          required int rotation}) async =>
      {
        'status': status,
        'match': id == null ? null : {'poiId': id}
      };
}

class _ThrowingCamera extends FakeStudioCamera {
  @override
  Future<void> initialize() async =>
      throw CameraException('CameraAccessDenied', 'denied');
}

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

/// Untuk layar dengan animasi tanpa akhir (spinner kamera).
Future<void> _pumpFor(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  // ---------------------------------------------------------------- DF-01
  group('DF-01 trigger saat memasuki radius museum', () {
    late TriggerEngine engine;
    late List<MuseumEvent> events;
    setUp(() {
      engine = TriggerEngine()..setPois(loadDataset());
      events = [];
      engine.museumEvents.listen(events.add);
    });
    tearDown(() => engine.dispose());

    test('masuk area museum memicu event sambutan sekali per sesi', () async {
      engine.updatePosition(_insideMuseum);
      engine.updatePosition(_insideMuseum);
      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(1));
      expect(events.single.type, MuseumEventType.entered);
      expect(events.single.firstThisSession, isTrue);
      expect(engine.isInsideMuseum, isTrue);
      // Tidak ada POI yang terpicu dari posisi 82 m (yang terpicu hanya museum).
      expect(engine.triggeredThisSession, isEmpty);

      engine.updatePosition(_farAway);
      engine.updatePosition(_insideMuseum);
      await Future<void>.delayed(Duration.zero);
      expect(events.map((e) => e.type),
          [MuseumEventType.entered, MuseumEventType.exited, MuseumEventType.entered]);
      expect(events.last.firstThisSession, isFalse,
          reason: 'sambutan tidak diulang pada kunjungan yang sama');
    });

    test('kunjungan baru (resetSession) menyambut lagi setelah masuk ulang',
        () async {
      engine.updatePosition(_insideMuseum);
      engine.resetSession();
      engine.updatePosition(_farAway);
      engine.updatePosition(_insideMuseum);
      await Future<void>.delayed(Duration.zero);
      expect(events.where((e) => e.firstThisSession), hasLength(2));
    });

    test('sesi yang dipulihkan setelah app dibuka ulang tidak menyambut dua kali',
        () async {
      engine.restoreSession(const [], museumWelcomed: true);
      engine.updatePosition(_insideMuseum);
      await Future<void>.delayed(Duration.zero);
      expect(events.single.firstThisSession, isFalse);
    });

    test('posisi GPS dengan akurasi buruk diabaikan', () async {
      engine.updatePosition(_pos(-6.902054, 107.619743, accuracy: 80));
      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });

    testWidgets('aplikasi utuh: masuk museum -> sambutan muncul -> Pindai QR',
        (tester) async {
      final prefs = await _prefs({
        AppConstants.prefOnboardingSeen: true,
        exploreTutorialSeenKey: true,
      });
      final positions = StreamController<UserPosition>.broadcast();
      addTearDown(positions.close);
      final narration = FakeNarration();
      await tester.pumpWidget(ProviderScope(overrides: [
        ...baseOverrides(prefs, narration: narration),
        positionStreamProvider.overrideWith((ref) => positions.stream),
      ], child: const JejakPosApp()));
      await _settle(tester);
      expect(find.text('Selamat datang di Museum Pos Indonesia'),
          findsOneWidget); // beranda Jelajah tampil
      expect(find.byType(MuseumWelcomeDialog), findsNothing);

      positions.add(_insideMuseum);
      await _settle(tester);
      expect(find.byType(MuseumWelcomeDialog), findsOneWidget);
      expect(find.text('Selamat datang di Museum Pos Indonesia!'),
          findsOneWidget);
      // Pemandu suara ikut menyambut.
      expect(narration.spoken.single.first,
          'Selamat datang di Museum Pos Indonesia!');
      expect(prefs.getBool(AppConstants.prefSessionMuseumWelcomed), isTrue);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Pindai QR koleksi'));
      await _settle(tester);
      expect(find.byType(MuseumWelcomeDialog), findsNothing);
      expect(find.byType(QrScannerScreen), findsOneWidget);

      // Pembacaan berikutnya di dalam museum tidak memunculkan sambutan lagi.
      positions.add(_insideMuseum);
      await _settle(tester);
      expect(find.byType(MuseumWelcomeDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tombol sambutan mengembalikan aksi yang dipilih',
        (tester) async {
      for (final entry in {
        'Mulai tur terpandu': MuseumWelcomeAction.tour,
        'Kenali pameran': MuseumWelcomeAction.recognize,
        'Pindai QR koleksi': MuseumWelcomeAction.qr,
        'Nanti saja': MuseumWelcomeAction.later,
      }.entries) {
        MuseumWelcomeAction? result;
        await tester.pumpWidget(MaterialApp(
            home: Builder(
                builder: (context) => TextButton(
                    onPressed: () async =>
                        result = await showMuseumWelcomeDialog(context),
                    child: const Text('buka')))));
        await tester.tap(find.text('buka'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(result, entry.value);
      }
    });
  });

  // ---------------------------------------------------------------- DF-02
  group('DF-02 Kenali memberi pesan saat objek bukan POI', () {
    late _NativeStub native;
    late ProviderContainer container;
    late VisionTourController controller;
    late TriggerEngine engine;

    Future<void> frame() => controller.processSiftFrame(
        bytes: Uint8List(16),
        width: 4,
        height: 4,
        stride: 4,
        pixelStride: 1,
        rotation: 90);

    setUp(() async {
      native = _NativeStub();
      final pois = loadDataset();
      engine = TriggerEngine()..setPois(pois);
      container = ProviderContainer(overrides: [
        siftRecognizerProvider.overrideWithValue(native),
        poisProvider.overrideWith((ref) async => pois),
        positionStreamProvider.overrideWith((ref) => const Stream.empty()),
        triggerEngineProvider.overrideWithValue(engine),
      ]);
      final sub = container.listen(visionTourControllerProvider, (_, __) {});
      addTearDown(sub.close);
      for (var i = 0;
          i < 40 &&
              container.read(visionTourControllerProvider).status ==
                  VisionTourStatus.loading;
          i++) {
        await Future<void>.delayed(Duration.zero);
      }
      controller = container.read(visionTourControllerProvider.notifier);
    });
    tearDown(() {
      container.dispose();
      engine.dispose();
    });

    VisionTourState read() => container.read(visionTourControllerProvider);

    test('bantuan muncul setelah 6 frame tanpa POI (unknown & ambiguous)',
        () async {
      for (var i = 0; i < 5; i++) {
        native.status = i.isEven ? 'unknown' : 'ambiguous';
        await frame();
        expect(read().showNotRecognizedHelp, isFalse);
      }
      await frame();
      expect(read().showNotRecognizedHelp, isTrue);
      expect(engine.triggeredThisSession, isEmpty,
          reason: 'objek bukan POI tetap tidak memicu apa pun');
    });

    test('POI yang mulai dikenali / tombol coba lagi mereset bantuan',
        () async {
      for (var i = 0; i < 6; i++) {
        await frame();
      }
      expect(read().showNotRecognizedHelp, isTrue);
      native
        ..status = 'recognized'
        ..id = 'P03';
      await frame();
      expect(read().showNotRecognizedHelp, isFalse);
      expect(read().noMatchFrames, 0);

      native
        ..status = 'unknown'
        ..id = null;
      for (var i = 0; i < 6; i++) {
        await frame();
      }
      controller.resetRecognition();
      expect(read().showNotRecognizedHelp, isFalse);
    });

    test('ID dari pengenal yang tidak ada di dataset dihitung tidak dikenali',
        () async {
      native
        ..status = 'recognized'
        ..id = 'P99';
      for (var i = 0; i < 6; i++) {
        await frame();
      }
      expect(read().showNotRecognizedHelp, isTrue);
    });

    testWidgets('layar Kenali menampilkan pesan + Pindai QR / Daftar POI',
        (tester) async {
      final native = _NativeStub();
      final engine = TriggerEngine()..setPois(loadDataset());
      addTearDown(engine.dispose);
      final router = GoRouter(initialLocation: '/kenali', routes: [
        GoRoute(path: '/kenali', builder: (_, __) => const VisionTourScreen()),
        GoRoute(
            path: '/qr',
            builder: (_, __) => const Scaffold(body: Text('Layar QR'))),
        GoRoute(
            path: '/pois',
            builder: (_, __) => const Scaffold(body: Text('Daftar'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        siftRecognizerProvider.overrideWithValue(native),
        poisProvider.overrideWith((ref) async => loadDataset()),
        positionStreamProvider.overrideWith((ref) => const Stream.empty()),
        triggerEngineProvider.overrideWithValue(engine),
      ], child: MaterialApp.router(routerConfig: router)));
      await _pumpFor(tester);
      final container = ProviderScope.containerOf(
          tester.element(find.byType(VisionTourScreen)));
      final c = container.read(visionTourControllerProvider.notifier);
      expect(find.text('Koleksi ini belum dikenali'), findsNothing);
      for (var i = 0; i < 6; i++) {
        await c.processSiftFrame(
            bytes: Uint8List(16),
            width: 4,
            height: 4,
            stride: 4,
            pixelStride: 1,
            rotation: 90);
      }
      await tester.pump();
      expect(find.text('Koleksi ini belum dikenali'), findsOneWidget);
      expect(find.textContaining('bukan koleksi POI'), findsOneWidget);
      await tester.tap(find.text('Pindai QR'));
      await _pumpFor(tester);
      expect(find.text('Layar QR'), findsOneWidget);
      router.pop();
      await _pumpFor(tester);
      await tester.tap(find.text('Coba koleksi lain'));
      await tester.pump();
      expect(find.text('Koleksi ini belum dikenali'), findsNothing);
    });
  });

  // ---------------------------------------------------------------- DF-03
  group('DF-03 narasi bisa dijeda dan dilanjutkan', () {
    test('pemecah kalimat tidak memotong singkatan & angka desimal', () {
      expect(
          splitIntoSentences([
            'Surat Emas panjangnya 1.5 m. Ditulis oleh R. Dijar! Benarkah?',
            '  ',
            'Bagian dua.'
          ]),
          [
            'Surat Emas panjangnya 1.5 m.',
            'Ditulis oleh R. Dijar!',
            'Benarkah?',
            'Bagian dua.'
          ]);
    });

    test('jeda di tengah kalimat lalu lanjut dari kalimat itu, bukan dari awal',
        () async {
      final said = <String>[];
      Completer<void>? current;
      final q = ResumableSpeechQueue(
        speakOne: (t) {
          said.add(t);
          current = Completer<void>();
          return current!.future;
        },
        stopEngine: () async {
          if (current != null && !current!.isCompleted) current!.complete();
        },
      );
      final statuses = <NarrationStatus>[];
      q.status.listen(statuses.add);

      unawaited(q.start(['Satu. Dua. Tiga.']));
      await Future<void>.delayed(Duration.zero);
      expect(said, ['Satu.']);
      current!.complete(); // kalimat 1 selesai
      await Future<void>.delayed(Duration.zero);
      expect(said, ['Satu.', 'Dua.']);

      await q.pause(); // dijeda di tengah "Dua."
      await Future<void>.delayed(Duration.zero);
      expect(q.current, NarrationStatus.paused);
      expect(q.position, 1);
      expect(said, ['Satu.', 'Dua.'], reason: 'tidak lanjut saat dijeda');

      unawaited(q.resume());
      await Future<void>.delayed(Duration.zero);
      expect(said, ['Satu.', 'Dua.', 'Dua.'],
          reason: 'lanjut dari kalimat yang terpotong');
      current!.complete();
      await Future<void>.delayed(Duration.zero);
      current!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(said, ['Satu.', 'Dua.', 'Dua.', 'Tiga.']);
      expect(q.current, NarrationStatus.idle);
      expect(statuses, [
        NarrationStatus.speaking,
        NarrationStatus.paused,
        NarrationStatus.speaking,
        NarrationStatus.idle
      ]);
    });

    test('stop menghapus posisi; resume setelah stop tidak berbuat apa-apa',
        () async {
      final said = <String>[];
      final q = ResumableSpeechQueue(
          speakOne: (t) async => said.add(t), stopEngine: () async {});
      final gate = Completer<void>();
      final blocking = ResumableSpeechQueue(
          speakOne: (t) {
            said.add(t);
            return gate.future;
          },
          stopEngine: () async {});
      unawaited(blocking.start(['Aa. Bb.']));
      await Future<void>.delayed(Duration.zero);
      await blocking.stop();
      await blocking.resume();
      expect(blocking.current, NarrationStatus.idle);
      expect(said, ['Aa.']);
      // pause saat idle diabaikan
      await q.pause();
      expect(q.current, NarrationStatus.idle);
    });

    testWidgets('bar pemandu suara: Jeda -> Lanjutkan -> Hentikan',
        (tester) async {
      final prefs = await _prefs();
      final narration = FakeNarration();
      await tester.pumpWidget(ProviderScope(
          overrides: baseOverrides(prefs, narration: narration),
          child: const MaterialApp(
              home: Scaffold(bottomNavigationBar: VoiceGuideBar()))));
      final container =
          ProviderScope.containerOf(tester.element(find.byType(VoiceGuideBar)));
      final poi = loadDataset().first;
      await container.read(voiceGuideProvider.notifier).narratePoi(poi);
      await tester.pump();
      expect(find.byTooltip('Jeda narasi'), findsOneWidget);
      expect(find.text('Cerita ${poi.name}'), findsOneWidget);

      await tester.tap(find.byTooltip('Jeda narasi'));
      await tester.pump();
      expect(narration.pauses, 1);
      expect(find.byTooltip('Lanjutkan narasi'), findsOneWidget);
      expect(find.textContaining('Dijeda'), findsOneWidget);
      expect(find.byTooltip('Hentikan suara'), findsOneWidget);

      await tester.tap(find.byTooltip('Lanjutkan narasi'));
      await tester.pump();
      expect(narration.resumes, 1);
      expect(narration.spoken, hasLength(1),
          reason: 'lanjutkan tidak mengulang narasi dari awal');
      expect(find.byTooltip('Jeda narasi'), findsOneWidget);

      await tester.tap(find.byTooltip('Hentikan suara'));
      await tester.pump();
      expect(find.byTooltip('Jeda narasi'), findsNothing);
      expect(find.byTooltip('Lanjutkan narasi'), findsNothing);
    });
  });

  // ---------------------------------------------------------------- DF-04
  group('DF-04 Photo Studio saat izin kamera ditolak', () {
    Future<void> pumpStudio(WidgetTester tester, FakeCameraPermission gate,
        {StudioCamera Function()? camera}) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(overrides: [
        studioCameraFactoryProvider
            .overrideWithValue(camera ?? FakeStudioCamera.new),
        studioCameraPermissionProvider.overrideWithValue(gate),
      ], child: const MaterialApp(home: PhotoStudioScreen(poiId: 'P04'))));
      await _settle(tester);
    }

    testWidgets('ditolak -> pesan izin + tombol minta ulang -> kamera menyala',
        (tester) async {
      final gate = FakeCameraPermission(AppPermissionStatus.denied);
      await pumpStudio(tester, gate);
      expect(gate.requests, 1, reason: 'dialog izin otomatis hanya sekali');
      expect(find.text('Menyiapkan kamera...'), findsNothing);
      expect(find.text('Izin kamera dibutuhkan'), findsOneWidget);
      expect(find.text('Izinkan kamera'), findsOneWidget);
      final shutter = tester.widget<FilledButton>(find.ancestor(
          of: find.byIcon(Icons.camera_alt),
          matching: find.byWidgetPredicate((w) => w is FilledButton)));
      expect(shutter.onPressed, isNull);

      gate.afterRequest = AppPermissionStatus.granted;
      await tester.tap(find.text('Izinkan kamera'));
      await _settle(tester);
      expect(gate.requests, 2);
      expect(find.byKey(const Key('live-preview')), findsOneWidget);
      expect(find.text('Izin kamera dibutuhkan'), findsNothing);
    });

    testWidgets('ditolak permanen -> Buka Pengaturan -> kembali & diizinkan',
        (tester) async {
      final gate = FakeCameraPermission(AppPermissionStatus.permanentlyDenied);
      await pumpStudio(tester, gate);
      expect(gate.requests, 0, reason: 'Android tidak lagi menampilkan dialog');
      expect(find.text('Buka Pengaturan'), findsOneWidget);
      await tester.tap(find.text('Buka Pengaturan'));
      await _settle(tester);
      expect(gate.settingsOpened, 1);

      // Pengguna mengaktifkan kamera di Pengaturan lalu kembali ke aplikasi.
      gate.current = AppPermissionStatus.granted;
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _settle(tester);
      expect(find.byKey(const Key('live-preview')), findsOneWidget);
    });

    testWidgets('plugin kamera melapor CameraAccessDenied -> pesan izin',
        (tester) async {
      await pumpStudio(tester, FakeCameraPermission(),
          camera: _ThrowingCamera.new);
      expect(find.text('Izin kamera dibutuhkan'), findsOneWidget);
      expect(find.text('Menyiapkan kamera...'), findsNothing);
    });

    testWidgets('izin sudah diberikan -> tidak meminta izin lagi',
        (tester) async {
      final gate = FakeCameraPermission();
      await pumpStudio(tester, gate);
      expect(gate.requests, 0);
      expect(find.byKey(const Key('live-preview')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------- DF-05
  group('DF-05 ringkasan & riwayat kunjungan tersimpan permanen', () {
    ProviderContainer newApp(SharedPreferences prefs) {
      final c = ProviderContainer(overrides: baseOverrides(prefs));
      addTearDown(c.dispose);
      return c;
    }

    test('ditutup lalu dibuka lagi: ringkasan tiap kunjungan tetap ada',
        () async {
      final prefs = await _prefs();
      var app = newApp(prefs);
      await app.read(progressProvider.future);
      await app.read(progressProvider.notifier).markVisited('P01');
      await app.read(progressProvider.notifier).markVisited('P02');
      await app.read(progressProvider.notifier).collectStamp('STP-P01');
      await app.read(activityStatsProvider.notifier).addQuizCompleted();
      await app.read(activityStatsProvider.notifier).addPhoto();
      await app.read(visitSessionProvider).endVisit();
      app.dispose();

      // "Aplikasi dibuka kembali": container & prefs baru dari penyimpanan.
      final reopened = await SharedPreferences.getInstance();
      app = newApp(reopened);
      var visits = app.read(activityStatsProvider).visits;
      expect(visits, hasLength(1));
      expect(visits.single.poiIds, ['P01', 'P02']);
      expect(visits.single.stampIds, ['STP-P01']);
      expect(visits.single.quizCompleted, 1);
      expect(visits.single.photoCount, 1);
      expect(visits.single.activityLine, '2 POI, 1 prangko, 1 kuis, 1 foto');

      // Kunjungan kedua hanya mencatat aktivitas barunya.
      await app.read(progressProvider.future);
      await app.read(progressProvider.notifier).markVisited('P03');
      await app.read(visitSessionProvider).endVisit();
      visits = newApp(await SharedPreferences.getInstance())
          .read(activityStatsProvider)
          .visits;
      expect(visits, hasLength(2));
      expect(visits.last.poiIds, ['P03']);
      expect(visits.last.totalVisited, 3);
      expect(visits.last.quizCompleted, 0);
    });

    test('data cap versi lama tetap tampil; data rusak tidak membuat crash',
        () async {
      final prefs = await _prefs({
        AppConstants.prefPostmarks: ['2026-11-20T10:00:00.000'],
        AppConstants.prefVisitHistory: '{rusak',
      });
      final visits = newApp(prefs).read(activityStatsProvider).visits;
      expect(visits, hasLength(1));
      expect(visits.single.endedAt, DateTime(2026, 11, 20, 10));
    });

    test('Hapus progres juga menghapus riwayat', () async {
      final prefs = await _prefs();
      final app = newApp(prefs);
      await app.read(progressProvider.future);
      await app.read(visitSessionProvider).endVisit();
      await app.read(progressProvider.notifier).reset();
      app.invalidate(activityStatsProvider);
      expect(app.read(activityStatsProvider).visits, isEmpty);
    });

    testWidgets('tab Progres & Ringkasan menampilkan riwayat setelah dibuka ulang',
        (tester) async {
      final prefs = await _prefs();
      final first = ProviderContainer(overrides: baseOverrides(prefs));
      await first.read(progressProvider.future);
      await first.read(progressProvider.notifier).markVisited('P01');
      await first.read(visitSessionProvider).endVisit();
      first.dispose();

      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
          overrides: baseOverrides(prefs),
          child: MaterialApp(theme: AppTheme.light, home: const ProgressScreen())));
      await _settle(tester);
      await tester.scrollUntilVisible(find.text('Riwayat kunjungan'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Kunjungan #1'), findsOneWidget);
      expect(find.textContaining('1 POI, 0 prangko, 0 kuis, 0 foto'),
          findsOneWidget);

      await tester.pumpWidget(ProviderScope(
          overrides: baseOverrides(prefs),
          child: MaterialApp(
              theme: AppTheme.light, home: const VisitSummaryScreen())));
      await _settle(tester);
      await tester.scrollUntilVisible(find.textContaining('Kunjungan #1'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Koleksi baru:'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------- DF-06
  group('DF-06 tombol dialog prangko langsung merespons sekali tekan', () {
    for (final entry in {
      'Scan koleksi lain': 'Layar /qr',
      'Lihat album': 'Layar /album',
      'Kembali ke jelajah': 'Layar /explore',
    }.entries) {
      testWidgets('ambil prangko baru -> "${entry.key}" sekali tekan',
          (tester) async {
        final prefs = await _prefs();
        await tester.binding.setSurfaceSize(const Size(400, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final router = GoRouter(initialLocation: '/explore', routes: [
          for (final p in ['/explore', '/album', '/qr'])
            GoRoute(
                path: p,
                builder: (context, _) => Scaffold(
                    body: Column(children: [
                      Text('Layar $p'),
                      TextButton(
                          onPressed: () => context.push('/poi/P01'),
                          child: const Text('buka P01')),
                    ]))),
          GoRoute(
              path: '/poi/:id',
              builder: (_, s) =>
                  PoiDetailScreen(poiId: s.pathParameters['id']!)),
        ]);
        addTearDown(router.dispose);
        await tester.pumpWidget(ProviderScope(
            overrides: baseOverrides(prefs),
            child: MaterialApp.router(
                theme: AppTheme.light, routerConfig: router)));
        await _settle(tester);
        await tester.tap(find.text('buka P01'));
        await _settle(tester);
        await tester.scrollUntilVisible(
            find.text('Selesai & ambil prangko'), 300,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.text('Selesai & ambil prangko'));
        await _settle(tester);
        expect(find.text('Prangko baru'), findsOneWidget);
        await tester.ensureVisible(find.text(entry.key));
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.key));
        await _settle(tester);
        expect(find.text(entry.value), findsOneWidget,
            reason: 'harus pindah pada tekanan pertama');
        expect(find.byType(PoiDetailScreen), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ---------------------------------------------------------------- DF-07
  group('DF-07 pemandu tur terintegrasi & dua arah', () {
    testWidgets('Detail POI: Tanya pemandu -> chat menjawab dari data POI',
        (tester) async {
      final prefs = await _prefs();
      final narration = FakeNarration();
      final poi = loadDataset().firstWhere((p) => p.id == 'P01');
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
          overrides: baseOverrides(prefs, narration: narration),
          child: MaterialApp(
              theme: AppTheme.light,
              home: const PoiDetailScreen(poiId: 'P01'))));
      await _settle(tester);
      expect(find.text('Tanya pemandu'), findsOneWidget);
      await tester.tap(find.text('Tanya pemandu'));
      await _settle(tester);
      expect(find.textContaining('Kamu sedang di ${poi.name}'), findsOneWidget);

      await tester.ensureVisible(find.text('Fakta menarik'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fakta menarik'));
      await _settle(tester);
      expect(find.textContaining('Fakta 1 dari ${poi.keyFacts.length}'),
          findsOneWidget);
      await tester.ensureVisible(find.text('Fakta menarik'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fakta menarik'));
      await _settle(tester);
      if (poi.keyFacts.length > 1) {
        expect(find.textContaining('Fakta 2 dari'), findsOneWidget);
      }
      await tester.ensureVisible(find.text('Ke mana setelah ini?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ke mana setelah ini?'));
      await _settle(tester);
      expect(find.textContaining('Setelah ini, coba'), findsOneWidget);
      await tester.ensureVisible(find.text('Bacakan untukku'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bacakan untukku'));
      await _settle(tester);
      expect(narration.spoken, isNotEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('saran pemandu sama di Pemandu tur dan Progres',
        (tester) async {
      final prefs = await _prefs({
        AppConstants.prefVisitedIds: ['P01', 'P02'],
      });
      final c = ProviderContainer(overrides: baseOverrides(prefs));
      addTearDown(c.dispose);
      final next = (await c.read(recommendedNextPoiProvider.future))!;
      final expected = 'Berikutnya: ${next.id} ${next.name}';

      for (final screen in [
        const VisualTourGuideScreen(),
        const ProgressScreen(),
      ]) {
        await tester.pumpWidget(UncontrolledProviderScope(
            container: c,
            child: MaterialApp(theme: AppTheme.light, home: screen)));
        await _settle(tester);
        expect(find.text(expected), findsOneWidget,
            reason: '${screen.runtimeType} harus menampilkan saran yang sama');
        expect(find.text('Saran pemandu'), findsOneWidget);
      }
    });
  });

  // ---------------------------------------------------------------- DF-08
  group('DF-08 animasi stempel terintegrasi di Ringkasan kunjungan', () {
    Future<SharedPreferences> endedTwice() async {
      final prefs = await _prefs();
      final c = ProviderContainer(overrides: baseOverrides(prefs));
      await c.read(progressProvider.future);
      await c
          .read(activityStatsProvider.notifier)
          .recordVisit(DateTime(2026, 11, 20, 9));
      await c
          .read(activityStatsProvider.notifier)
          .recordVisit(DateTime(2026, 11, 27, 9));
      c.dispose();
      return prefs;
    }

    testWidgets('setelah Akhiri kunjungan: animasi berjalan, cap memakai tanggal asli',
        (tester) async {
      final prefs = await endedTwice();
      await tester.pumpWidget(ProviderScope(
          overrides: baseOverrides(prefs),
          child: const MaterialApp(home: VisitSummaryScreen(justEnded: true))));
      await tester.pump();
      final card = tester
          .widget<PassportPostmarkCard>(find.byType(PassportPostmarkCard));
      expect(card.triggerStampAnimation, isTrue);
      expect(card.visitDate, '27.11.2026');
      expect(card.previousVisitDates, ['20.11.2026']);
      expect(card.totalVisits, 2);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Mengecap paspor...'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.textContaining('Tercap Resmi'), findsOneWidget);
      expect(find.text('KARTU JEJAK KUNJUNGAN'), findsOneWidget);
      expect(find.text('14.08.2026'), findsNothing,
          reason: 'tanggal contoh tidak boleh tampil');
      expect(find.text('20.11.2026'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Nama penjelajah disimpan.
      await tester.enterText(find.byType(TextField), 'Diva');
      expect(prefs.getString(visitorNamePrefKey), 'Diva');
    });

    testWidgets('dibuka dari riwayat: cap langsung tampil tanpa animasi',
        (tester) async {
      final prefs = await endedTwice();
      await tester.pumpWidget(ProviderScope(
          overrides: baseOverrides(prefs),
          child: const MaterialApp(home: VisitSummaryScreen())));
      await tester.pump();
      expect(find.textContaining('Tercap Resmi'), findsOneWidget);
      expect(find.text('Mengecap paspor...'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('belum pernah mengakhiri kunjungan: kartu tidak tampil',
        (tester) async {
      final prefs = await _prefs();
      await tester.pumpWidget(ProviderScope(
          overrides: baseOverrides(prefs),
          child: const MaterialApp(home: VisitSummaryScreen())));
      await _settle(tester);
      expect(find.byType(PassportPostmarkCard), findsNothing);
      expect(find.textContaining('Akhiri kunjungan'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------- DF-09
  testWidgets('DF-09 Pindai QR langsung menyalakan kamera (sinkron dengan Kenali)',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: QrScannerScreen())));
    await tester.pump();
    expect(find.byType(MobileScanner), findsOneWidget);
    expect(find.text('Matikan kamera'), findsOneWidget);
    expect(find.textContaining('Kamera nonaktif'), findsNothing);
    await tester.tap(find.text('Matikan kamera'));
    await tester.pump();
    expect(find.byType(MobileScanner), findsNothing);
    expect(find.text('Aktifkan kamera'), findsOneWidget);
  });

  // ---------------------------------------------------------------- DF-10
  group('DF-10 Photo Studio tidak terlalu zoom', () {
    for (final aspect in [9 / 16, 3 / 4]) {
      testWidgets('kanvas mengikuti rasio kamera ${aspect.toStringAsFixed(3)}',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(ProviderScope(overrides: [
          studioCameraFactoryProvider
              .overrideWithValue(() => _AspectCamera(aspect)),
          studioCameraPermissionProvider
              .overrideWithValue(FakeCameraPermission()),
        ], child: const MaterialApp(home: PhotoStudioScreen())));
        await _settle(tester);
        final canvas = tester.widget<AspectRatio>(find
            .ancestor(
                of: find.byKey(const Key('live-preview')),
                matching: find.byType(AspectRatio))
            .first);
        expect(canvas.aspectRatio, closeTo(aspect, 1e-9),
            reason: 'preview tidak dipotong (cover = pas)');
        final size = tester.getSize(find.byKey(const Key('live-preview')));
        expect(size.width / size.height, closeTo(aspect, 0.01));
      });
    }
  });

  // ---------------------------------------------------------------- DF-11
  testWidgets('DF-11 "Petunjuk lain" terlihat jelas sebelum pilihan tebakan',
      (tester) async {
    final poi = loadDataset().firstWhere((p) => p.id == 'P08');
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        overrides: [poiByIdProvider('P08').overrideWith((ref) async => poi)],
        child: MaterialApp(
            theme: AppTheme.light,
            home: const MysteryClueScreen(poiId: 'P08'))));
    await _settle(tester);
    final remaining = poi.mysteryClues.length - 1;
    expect(find.text('Masih ada $remaining petunjuk lagi. Buka dulu sebelum menebak!'),
        findsOneWidget);
    // Terlihat di layar pertama tanpa menggulir, di atas gambar & pilihan.
    final button = tester.getRect(find.text('Petunjuk lain'));
    expect(button.bottom, lessThan(740));
    expect(find.widgetWithText(FilledButton, 'Petunjuk lain'), findsOneWidget);

    for (var i = 0; i < remaining; i++) {
      await tester.tap(find.text('Petunjuk lain'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Semua petunjuk sudah terbuka. Saatnya menebak!'),
        findsOneWidget);
    expect(find.text('Petunjuk lain'), findsNothing);
    expect(find.text('Petunjuk ${poi.mysteryClues.length}'), findsOneWidget);
  });

  // ------------------------------------------- Skenario layar kecil/huruf besar
  group('UI baru tidak overflow di layar kecil & huruf besar', () {
    for (final width in [320.0, 412.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('lebar $width, skala huruf $scale', (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 720));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final prefs = await _prefs();
          final c = ProviderContainer(overrides: baseOverrides(prefs));
          addTearDown(c.dispose);
          await c.read(progressProvider.future);
          await c.read(progressProvider.notifier).markVisited('P01');
          await c.read(activityStatsProvider.notifier).recordVisit();
          await c.read(activityStatsProvider.notifier).recordVisit();

          Widget app(Widget home) => UncontrolledProviderScope(
              container: c,
              child: MaterialApp(
                  key: UniqueKey(),
                  theme: AppTheme.light,
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!),
                  home: home));

          await tester.pumpWidget(app(const VisitSummaryScreen(justEnded: true)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Ringkasan');

          await tester.pumpWidget(app(const ProgressScreen()));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Progres');

          await tester.pumpWidget(app(const PoiDetailScreen(poiId: 'P02')));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Tanya pemandu'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Chat pemandu');

          await tester.pumpWidget(app(Builder(
              builder: (context) => TextButton(
                  onPressed: () => showMuseumWelcomeDialog(context),
                  child: const Text('buka')))));
          await tester.tap(find.text('buka'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Sambutan museum');

          await tester.pumpWidget(app(const VisualTourGuideScreen()));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Pemandu tur');

          await tester.pumpWidget(ProviderScope(
              overrides: [
                studioCameraFactoryProvider
                    .overrideWithValue(FakeStudioCamera.new),
                studioCameraPermissionProvider.overrideWithValue(
                    FakeCameraPermission(AppPermissionStatus.permanentlyDenied)),
              ],
              child: MaterialApp(
                  theme: AppTheme.light,
                  builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!),
                  home: const PhotoStudioScreen())));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Izin kamera');
        });
      }
    }
  });
}

class _AspectCamera extends FakeStudioCamera {
  _AspectCamera(this._aspect);
  final double _aspect;
  @override
  double get aspectRatio => _aspect;
  @override
  Widget preview() =>
      const ColoredBox(key: Key('live-preview'), color: Colors.blue);
}
