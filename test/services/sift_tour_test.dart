import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jejakpos/features/vision_tour/state/vision_tour_controller.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/services/trigger_engine.dart';
import 'package:jejakpos/services/vision/sift_recognizer.dart';
import 'package:jejakpos/services/vision/vision_matcher.dart';
import '../helpers/test_data.dart';

class NativeStub extends SiftRecognizer {
  String? id = 'P01';
  String status = 'recognized';
  @override
  Future<int> initialize() async => 29;
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late NativeStub native;
  late ProviderContainer container;
  late TriggerEngine engine;
  late VisionTourController controller;
  setUp(() async {
    native = NativeStub();
    final pois = loadDataset();
    engine = TriggerEngine()..setPois(pois);
    container = ProviderContainer(overrides: [
      siftRecognizerProvider.overrideWithValue(native),
      poisProvider.overrideWith((ref) async => pois),
      positionStreamProvider.overrideWith((ref) => const Stream.empty()),
      triggerEngineProvider.overrideWithValue(engine)
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
    expect(container.read(visionTourControllerProvider).status,
        VisionTourStatus.ready);
    controller = container.read(visionTourControllerProvider.notifier);
    expect(controller.usesSift, isTrue);
  });
  tearDown(() {
    container.dispose();
    engine.dispose();
  });
  Future<VisionDecision?> frame() => controller.processSiftFrame(
      bytes: Uint8List(16),
      width: 4,
      height: 4,
      stride: 4,
      pixelStride: 1,
      rotation: 90);
  test('all 11 SIFT IDs trigger the corresponding POI after three frames',
      () async {
    for (var i = 1; i <= 11; i++) {
      final id = 'P${i.toString().padLeft(2, '0')}';
      native.id = id;
      expect((await frame())!.phase, VisionPhase.recognizing);
      expect(engine.hasTriggered(id), isFalse);
      expect((await frame())!.phase, VisionPhase.recognizing);
      expect((await frame())!.confirmedPoi?.id, id);
      expect(
          container.read(visionTourControllerProvider).recognizedPoi?.id, id);
    }
    expect(engine.triggeredThisSession.length, 11);
  });
  test('unknown, ambiguous, and unmapped IDs never trigger and reset stability',
      () async {
    await frame();
    await frame();
    native.status = 'unknown';
    native.id = null;
    expect((await frame())!.phase, VisionPhase.searching);
    native.status = 'recognized';
    native.id = 'P01';
    expect((await frame())!.streak, 1);
    native.status = 'ambiguous';
    native.id = null;
    expect((await frame())!.phase, VisionPhase.ambiguous);
    native.status = 'recognized';
    native.id = 'P99';
    expect((await frame())!.phase, VisionPhase.searching);
    native.id = 'P07';
    expect((await frame())!.streak, 1);
    expect(engine.triggeredThisSession, isEmpty);
    await frame();
    await frame();
    expect(container.read(visionTourControllerProvider).newlyTriggered, isTrue);
    await frame();
    await frame();
    await frame();
    expect(
        container.read(visionTourControllerProvider).newlyTriggered, isFalse);
  });
}
