// lib/features/vision_tour/state/vision_tour_controller.dart
// Tur dengan computer vision: frame kamera -> embedding -> cocokkan ke foto POI
// (+ petunjuk GPS) -> stabilisasi -> TriggerEngine.reportIdentification(vision).
// Setelah terpicu, app.dart membuka UI08 dan pemandu suara berjalan seperti biasa.

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
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
final imageEmbedderProvider = FutureProvider.autoDispose<ImageEmbedder>((ref) async {
  final embedder = await TfliteImageEmbedder.load();
  ref.onDispose(embedder.dispose);
  return embedder;
});

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

  @override
  VisionTourState build() {
    _stabilizer = VisionStabilizer(config: ref.watch(appConfigProvider));
    // Jaga GPS tetap aktif selama layar kamera terbuka (petunjuk lokasi).
    ref.listen(positionStreamProvider, (_, __) {});
    _init();
    return const VisionTourState();
  }

  Future<void> _init() async {
    try {
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
      AppLogger.error(_tag, 'Gagal memuat model vision', e);
      state = state.copyWith(
          status: VisionTourStatus.error,
          errorMessage: 'Pengenal pameran gagal dimuat. Pakai QR sebagai cadangan.');
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
      AppLogger.info(_tag,
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

  /// Mulai ulang pengenalan (misal setelah kembali dari halaman POI).
  void resetRecognition() {
    _stabilizer.reset();
    state = VisionTourState(status: state.status, errorMessage: state.errorMessage);
  }
}

final visionTourControllerProvider =
    NotifierProvider.autoDispose<VisionTourController, VisionTourState>(
        VisionTourController.new);
