// lib/features/vision_tour/state/vision_tour_controller.dart
// Tur dengan computer vision: frame kamera -> embedding -> cocokkan ke foto POI
// (+ petunjuk GPS) -> stabilisasi -> TriggerEngine.reportIdentification(vision).
// Setelah terpicu, app.dart membuka UI08 dan pemandu suara berjalan seperti biasa.

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../../../services/vision/sift_recognizer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/poi.dart';
import '../../../providers/providers.dart';
import '../../../services/trigger_engine.dart';
import '../../../services/vision/image_embedder.dart';
import '../../../services/vision/vision_matcher.dart';

/// Indeks foto referensi (dimuat sekali).
final visionIndexProvider =
    FutureProvider<VisionIndex>((ref) => VisionIndex.load(rootBundle));

/// Model embedding. Di-override di test dengan embedder palsu.
final imageEmbedderProvider =
    FutureProvider.autoDispose<ImageEmbedder>((ref) async {
  final embedder = await TfliteImageEmbedder.load();
  ref.onDispose(embedder.dispose);
  return embedder;
});

final siftRecognizerProvider = Provider<SiftRecognizer?>((ref) => kIsWeb
    ? const BrowserSiftRecognizer()
    : defaultTargetPlatform == TargetPlatform.android
        ? const SiftRecognizer()
        : null);

enum VisionTourStatus { loading, ready, error }

class VisionTourState {
  const VisionTourState({
    this.status = VisionTourStatus.loading,
    this.decision,
    this.recognizedPoi,
    this.newlyTriggered = false,
    this.errorMessage,
  });

  final VisionTourStatus status;
  final VisionDecision? decision;

  /// POI terakhir yang dikonfirmasi kamera.
  final Poi? recognizedPoi;

  /// true jika konfirmasi terakhir memicu POI baru (bukan yang sudah dikunjungi).
  final bool newlyTriggered;
  final String? errorMessage;

  VisionTourState copyWith({
    VisionTourStatus? status,
    VisionDecision? decision,
    Poi? recognizedPoi,
    bool? newlyTriggered,
    String? errorMessage,
  }) =>
      VisionTourState(
        status: status ?? this.status,
        decision: decision ?? this.decision,
        recognizedPoi: recognizedPoi ?? this.recognizedPoi,
        newlyTriggered: newlyTriggered ?? this.newlyTriggered,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class VisionTourController extends AutoDisposeNotifier<VisionTourState> {
  static const _tag = AppConstants.logTagVision;

  ImageEmbedder? _embedder;
  VisionMatcher? _matcher;
  late VisionStabilizer _stabilizer;
  List<Poi> _pois = const [];
  bool _busy = false;
  bool _alive = true;
  SiftRecognizer? _sift;
  String? _siftCandidate;
  int _siftStreak = 0;
  bool get usesSift => _sift != null;

  @override
  VisionTourState build() {
    _alive = true;
    ref.onDispose(() => _alive = false);
    _stabilizer = VisionStabilizer(config: ref.watch(appConfigProvider));
    // Jaga GPS tetap aktif selama layar kamera terbuka (petunjuk lokasi).
    ref.listen(positionStreamProvider, (_, __) {});
    _init();
    return const VisionTourState();
  }

  Future<void> _init() async {
    try {
      final native = ref.read(siftRecognizerProvider);
      if (native != null) {
        final count = await native.initialize();
        if (!_alive) return;
        final pois = await ref.read(poisProvider.future);
        if (!_alive) return;
        _pois = pois.where((p) => p.isBaseline).toList();
        _sift = native;
        AppLogger.info(_tag, 'SIFT offline siap: $count referensi');
        state = state.copyWith(status: VisionTourStatus.ready);
        return;
      }
      final config = ref.read(appConfigProvider);
      final index = await ref.read(visionIndexProvider.future);
      final embedder = await ref.read(imageEmbedderProvider.future);
      final pois = await ref.read(poisProvider.future);
      _embedder = embedder;
      _matcher = VisionMatcher(index, config: config);
      _pois = pois.where((p) => p.isBaseline).toList();
      AppLogger.info(_tag,
          'Siap: ${index.references.length} embedding, POI ${index.poiIds.length}');
      state = state.copyWith(status: VisionTourStatus.ready);
    } catch (e) {
      if (!_alive) return;
      AppLogger.error(_tag, 'Gagal memuat model vision', e);
      state = state.copyWith(
          status: VisionTourStatus.error,
          errorMessage:
              'Pengenal pameran gagal dimuat. Pakai QR sebagai cadangan.');
    }
  }

  bool get isBusy => _busy;

  /// Analisis satu frame (input 224x224x3 dari frame_converter). Frame yang
  /// datang saat analisis sebelumnya belum selesai diabaikan.
  Future<VisionDecision?> processFrame(Float32List input) async {
    final embedder = _embedder;
    final matcher = _matcher;
    if (_busy || embedder == null || matcher == null) return null;
    _busy = true;
    try {
      final embedding = await embedder.embed(input);
      final position = ref.read(positionStreamProvider).valueOrNull;
      final ranked = matcher.rank(embedding, pois: _pois, position: position);
      final decision = _stabilizer.feed(ranked);

      final poi = decision.confirmedPoi;
      if (poi == null) {
        state = state.copyWith(decision: decision);
        return decision;
      }

      _stabilizer.reset();
      final top = decision.top!;
      AppLogger.info(
          _tag,
          'Dikenali ${poi.id} (sim ${top.similarity.toStringAsFixed(2)}, '
          'gps ${top.distanceMeters?.toStringAsFixed(0) ?? '-'} m)');
      final event = ref
          .read(triggerEngineProvider)
          .reportIdentification(poi, TriggerSource.vision);
      state = VisionTourState(
        status: VisionTourStatus.ready,
        decision: decision,
        recognizedPoi: poi,
        newlyTriggered: event != null,
      );
      return decision;
    } catch (e) {
      AppLogger.error(_tag, 'Analisis frame gagal', e);
      return null;
    } finally {
      _busy = false;
    }
  }

  /// Full-resolution luminance plane; no 224px embedding crop on Android.
  Future<VisionDecision?> processSiftFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    required int stride,
    required int pixelStride,
    required int rotation,
    bool encodedImage = false,
  }) async {
    final native = _sift;
    if (_busy || native == null) return null;
    _busy = true;
    try {
      final result = encodedImage
          ? await native.recognizeImage(bytes)
          : await native.recognize(
              bytes: bytes,
              width: width,
              height: height,
              stride: stride,
              pixelStride: pixelStride,
              rotation: rotation);
      if (!_alive) return null;
      final need = ref.read(appConfigProvider).visionRequiredFrames;
      final raw = result['match'];
      final matches = raw is Map
          ? _pois.where((p) => p.id == raw['poiId']).toList()
          : <Poi>[];
      if (result['status'] != 'recognized' || matches.isEmpty) {
        _siftCandidate = null;
        _siftStreak = 0;
        final decision = VisionDecision(
          phase: result['status'] == 'ambiguous'
              ? VisionPhase.ambiguous
              : VisionPhase.searching,
          requiredFrames: need,
        );
        state =
            VisionTourState(status: VisionTourStatus.ready, decision: decision);
        return decision;
      }
      final poi = matches.single;
      _siftStreak = _siftCandidate == poi.id ? _siftStreak + 1 : 1;
      _siftCandidate = poi.id;
      final decision = VisionDecision(
        phase: _siftStreak >= need
            ? VisionPhase.confirmed
            : VisionPhase.recognizing,
        // Geometric verification passed; this marker is NOT cosine confidence.
        top: VisionScore(poi: poi, similarity: 1, gpsPenalty: 0),
        streak: _siftStreak, requiredFrames: need,
      );
      if (decision.phase == VisionPhase.confirmed) {
        final event = ref
            .read(triggerEngineProvider)
            .reportIdentification(poi, TriggerSource.vision);
        _siftCandidate = null;
        _siftStreak = 0;
        state = VisionTourState(
            status: VisionTourStatus.ready,
            decision: decision,
            recognizedPoi: poi,
            newlyTriggered: event != null);
      } else {
        state =
            VisionTourState(status: VisionTourStatus.ready, decision: decision);
      }
      return decision;
    } catch (e) {
      if (!_alive) return null;
      _siftCandidate = null;
      _siftStreak = 0;
      AppLogger.error(_tag, 'Analisis SIFT gagal', e);
      state = VisionTourState(
          status: VisionTourStatus.error,
          errorMessage:
              'Pengenalan kamera gagal. Buka ulang Kenali atau pakai QR.');
      return null;
    } finally {
      _busy = false;
    }
  }

  /// Mulai ulang pengenalan (misal setelah kembali dari halaman POI).
  void resetRecognition() {
    _stabilizer.reset();
    _siftCandidate = null;
    _siftStreak = 0;
    state =
        VisionTourState(status: state.status, errorMessage: state.errorMessage);
  }
}

final visionTourControllerProvider =
    NotifierProvider.autoDispose<VisionTourController, VisionTourState>(
        VisionTourController.new);
