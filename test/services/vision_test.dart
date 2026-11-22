// test/services/vision_test.dart
// Uji computer vision: konversi frame kamera, indeks referensi, pencocokan +
// penalti GPS, stabilisasi antar-frame, dan controller tur (embedder palsu).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/core/config/app_config.dart';
import 'package:jejakpos/data/models/models.dart';
import 'package:jejakpos/features/vision_tour/state/vision_tour_controller.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/services/trigger_engine.dart';
import 'package:jejakpos/services/vision/frame_converter.dart';
import 'package:jejakpos/services/vision/image_embedder.dart';
import 'package:jejakpos/services/vision/vision_matcher.dart';

import '../helpers/test_data.dart';

VisionIndex loadIndex() => VisionIndex.fromJson(
    jsonDecode(File(VisionIndex.assetPath).readAsStringSync()) as Map<String, dynamic>);

Float32List unit(int dim, int hot, [double noise = 0]) {
  final v = Float32List(dim)..fillRange(0, dim, noise);
  v[hot] = 1;
  return v;
}

VisionIndex fakeIndex(Map<String, int> poiToAxis, {int dim = 8}) => VisionIndex(
      dimension: dim,
      references: [
        for (final e in poiToAxis.entries)
          VisionReference(poiId: e.key, vector: unit(dim, e.value)),
      ],
    );

class FakeEmbedder implements ImageEmbedder {
  FakeEmbedder(this.output);
  Float32List output;
  int calls = 0;

  @override
  Future<Float32List> embed(Float32List rgb) async {
    calls++;
    return output;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('frame_converter', () {
    FramePlane solid(int w, int h, int value) =>
        FramePlane(bytes: Uint8List(w * h)..fillRange(0, w * h, value), bytesPerRow: w);

    test('YUV abu-abu netral -> RGB ~0.5, ukuran 224x224x3', () {
      final out = yuv420ToModelInput(
        width: 64,
        height: 48,
        y: solid(64, 48, 128),
        u: solid(32, 24, 128),
        v: solid(32, 24, 128),
      );
      expect(out.length, kVisionInputSize * kVisionInputSize * 3);
      expect(out.every((x) => (x - 128 / 255).abs() < 1e-6), isTrue);
    });

    test('V tinggi -> merah dominan; UV semi-planar (pixelStride 2) didukung', () {
      // NV21-like: U dan V berbagi buffer interleaved, pixelStride 2.
      final uv = Uint8List(32 * 24 * 2);
      for (var i = 0; i < uv.length; i += 2) {
        uv[i] = 128; // U
        uv[i + 1] = 220; // V
      }
      final out = yuv420ToModelInput(
        width: 64,
        height: 48,
        y: solid(64, 48, 100),
        u: FramePlane(bytes: uv, bytesPerRow: 64, bytesPerPixel: 2),
        v: FramePlane(bytes: Uint8List.sublistView(uv, 1), bytesPerRow: 64, bytesPerPixel: 2),
      );
      expect(out[0], greaterThan(out[1]));
      expect(out[0], greaterThan(out[2]));
    });

    test('rotasi sensor 90 derajat: kiri/kanan sensor menjadi atas/bawah', () {
      const w = 40, h = 40;
      final y = Uint8List(w * h);
      for (var r = 0; r < h; r++) {
        for (var c = 0; c < w; c++) {
          y[r * w + c] = c < w / 2 ? 0 : 255; // kiri gelap, kanan terang
        }
      }
      final out = yuv420ToModelInput(
        width: w,
        height: h,
        y: FramePlane(bytes: y, bytesPerRow: w),
        u: solid(20, 20, 128),
        v: solid(20, 20, 128),
        rotationDegrees: 90,
      );
      double lumaAt(int row, int col) => out[(row * kVisionInputSize + col) * 3];
      expect(lumaAt(5, 112), lessThan(0.1)); // atas = kiri sensor (gelap)
      expect(lumaAt(218, 112), greaterThan(0.9)); // bawah = kanan sensor (terang)
      expect((lumaAt(5, 5) - lumaAt(5, 218)).abs(), lessThan(1e-6));
    });

    test('BGRA dibaca sebagai RGB', () {
      final bytes = Uint8List(4 * 4 * 4);
      for (var i = 0; i < bytes.length; i += 4) {
        bytes[i] = 255; // B
        bytes[i + 1] = 0; // G
        bytes[i + 2] = 0; // R
        bytes[i + 3] = 255; // A
      }
      final out = bgraToModelInput(
          width: 4, height: 4, plane: FramePlane(bytes: bytes, bytesPerRow: 16));
      expect(out.sublist(0, 3), [0, 0, 1]);
    });
  });

  group('indeks referensi (assets/models/poi_vision_index.json)', () {
    test('semua POI baseline P01-P11 punya foto referensi berdimensi 1024', () {
      final index = loadIndex();
      expect(index.dimension, 1024);
      final baseline = loadDataset().where((p) => p.isBaseline).map((p) => p.id);
      expect(index.poiIds, containsAll(baseline));
    });

    test('model tflite ada dan referensi mengenali POI-nya sendiri', () {
      expect(File(TfliteImageEmbedder.modelAsset).existsSync(), isTrue);
      final index = loadIndex();
      final matcher = VisionMatcher(index);
      final pois = loadDataset();
      for (final r in index.references.take(30)) {
        expect(matcher.rank(r.vector, pois: pois).first.poi.id, r.poiId,
            reason: r.source);
      }
    });
  });

  group('VisionMatcher + GPS', () {
    final pois = loadDataset();
    final p01 = pois.firstWhere((p) => p.id == 'P01');
    final index = fakeIndex({'P01': 0, 'P08': 1, 'P12': 2});

    test('POI tanpa referensi dilewati, urut dari skor tertinggi', () {
      final ranked = VisionMatcher(index).rank(unit(8, 1, 0.1), pois: pois);
      expect(ranked.map((s) => s.poi.id), ['P08', 'P01', 'P12']);
      expect(ranked.first.gpsPenalty, 0);
    });

    test('GPS jauh dari POI memberi penalti lembut (maks visionGpsMaxPenalty)', () {
      const config = AppConfig();
      // Pengguna berdiri di P01 dengan akurasi 3 m. P08 ~25 m dari P01.
      final here = UserPosition(
          latitude: p01.latitude!,
          longitude: p01.longitude!,
          accuracyMeters: 3,
          timestamp: DateTime.now());
      // Frame sedikit lebih mirip P08 daripada P01.
      final emb = Float32List(8)
        ..[0] = 0.69
        ..[1] = 0.72;
      final ranked = VisionMatcher(index).rank(emb, pois: pois, position: here);
      final p08 = ranked.firstWhere((s) => s.poi.id == 'P08');
      expect(p08.gpsPenalty, greaterThan(0));
      expect(p08.gpsPenalty, lessThanOrEqualTo(config.visionGpsMaxPenalty));
      expect(ranked.first.poi.id, 'P01'); // GPS memecah keraguan
      expect(ranked.firstWhere((s) => s.poi.id == 'P01').gpsPenalty, 0);
    });

    test('GPS dengan akurasi buruk diabaikan', () {
      final bad = UserPosition(
          latitude: p01.latitude!,
          longitude: p01.longitude!,
          accuracyMeters: 80,
          timestamp: DateTime.now());
      final ranked = VisionMatcher(index).rank(unit(8, 1), pois: pois, position: bad);
      expect(ranked.every((s) => s.gpsPenalty == 0), isTrue);
    });
  });

  group('VisionStabilizer', () {
    final pois = loadDataset();
    final matcher = VisionMatcher(fakeIndex({'P01': 0, 'P02': 1}));

    test('butuh N frame berturut-turut sebelum konfirmasi', () {
      final s = VisionStabilizer();
      final ranked = matcher.rank(unit(8, 0), pois: pois);
      expect(s.feed(ranked).phase, VisionPhase.recognizing);
      expect(s.feed(ranked).phase, VisionPhase.recognizing);
      final d = s.feed(ranked);
      expect(d.phase, VisionPhase.confirmed);
      expect(d.confirmedPoi?.id, 'P01');
    });

    test('skor rendah -> searching, dua POI mirip -> ambiguous, dan streak direset', () {
      final s = VisionStabilizer();
      s.feed(matcher.rank(unit(8, 0), pois: pois));
      expect(s.feed(matcher.rank(unit(8, 5), pois: pois)).phase, VisionPhase.searching);
      final tie = Float32List(8)
        ..[0] = 1
        ..[1] = 0.99;
      expect(s.feed(matcher.rank(tie, pois: pois)).phase, VisionPhase.ambiguous);
      expect(s.feed(matcher.rank(unit(8, 0), pois: pois)).streak, 1);
    });

    test('POI teratas berganti -> streak mulai dari 1', () {
      final s = VisionStabilizer();
      s.feed(matcher.rank(unit(8, 0), pois: pois));
      s.feed(matcher.rank(unit(8, 0), pois: pois));
      final d = s.feed(matcher.rank(unit(8, 1), pois: pois));
      expect(d.top!.poi.id, 'P02');
      expect(d.streak, 1);
    });
  });

  group('VisionTourController', () {
    late ProviderContainer container;
    late FakeEmbedder embedder;
    late TriggerEngine engine;
    late VisionIndex index;

    setUp(() {
      index = loadIndex();
      final p04Ref = index.references.firstWhere((r) => r.poiId == 'P04').vector;
      embedder = FakeEmbedder(p04Ref);
      final pois = loadDataset();
      engine = TriggerEngine()..setPois(pois);
      container = ProviderContainer(overrides: [
        siftRecognizerProvider.overrideWithValue(null),
        poisProvider.overrideWith((ref) async => pois),
        visionIndexProvider.overrideWith((ref) async => index),
        imageEmbedderProvider.overrideWith((ref) async => embedder),
        positionStreamProvider.overrideWith((ref) => const Stream.empty()),
        triggerEngineProvider.overrideWithValue(engine),
      ]);
    });

    tearDown(() {
      container.dispose();
      engine.dispose();
    });

    Future<VisionTourController> ready() async {
      final sub = container.listen(visionTourControllerProvider, (_, __) {});
      addTearDown(sub.close);
      for (var i = 0; i < 20; i++) {
        if (container.read(visionTourControllerProvider).status !=
            VisionTourStatus.loading) {
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }
      expect(container.read(visionTourControllerProvider).status,
          VisionTourStatus.ready);
      return container.read(visionTourControllerProvider.notifier);
    }

    test('3 frame P04 -> POI terpicu lewat sumber vision', () async {
      final controller = await ready();
      final events = <TriggerEvent>[];
      final sub = engine.events.listen(events.add);
      addTearDown(sub.cancel);
      final frame = Float32List(kVisionInputSize * kVisionInputSize * 3);

      for (var i = 0; i < const AppConfig().visionRequiredFrames; i++) {
        await controller.processFrame(frame);
      }
      await Future<void>.delayed(Duration.zero);

      final state = container.read(visionTourControllerProvider);
      expect(state.recognizedPoi?.id, 'P04');
      expect(state.newlyTriggered, isTrue);
      expect(engine.hasTriggered('P04'), isTrue);
      expect(events.single.source, TriggerSource.vision);

      // Dikenali lagi -> tidak memicu ulang (sekali per sesi).
      for (var i = 0; i < const AppConfig().visionRequiredFrames; i++) {
        await controller.processFrame(frame);
      }
      expect(container.read(visionTourControllerProvider).newlyTriggered, isFalse);
      expect(embedder.calls, 2 * const AppConfig().visionRequiredFrames);
    });
  });
}
