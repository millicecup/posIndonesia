// lib/features/voice_guide/state/voice_guide_controller.dart
// Pemandu suara otomatis (Visual Tour Guide versi suara, F07):
// - Mendekati POI  -> "Kamu sedang mendekati ..."
// - Tiba di POI    -> lokasi + ringkasan + fakta + rekomendasi berikutnya
// - Tombol nyala/mati (tersimpan), Jeda/Lanjutkan (DF-03), Ulangi narasi terakhir, dan Stop.
// Saat dimatikan, narasi otomatis tidak diputar; tombol "Dengar" manual tetap bisa dipakai.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../../providers/providers.dart';
import '../../../services/narration_service.dart';
import '../../../services/trigger_engine.dart';
import 'narration_script.dart';

final narrationServiceProvider = Provider<NarrationService>((ref) {
  final service = TtsNarrationService();
  ref.onDispose(service.dispose);
  return service;
});

class VoiceGuideState {
  const VoiceGuideState(
      {required this.enabled,
      this.speaking = false,
      this.paused = false,
      this.last});

  /// Pemandu suara otomatis aktif.
  final bool enabled;
  final bool speaking;

  /// Narasi dijeda; bisa dilanjutkan dari kalimat terakhir.
  final bool paused;

  /// Narasi terakhir (untuk tombol Ulangi).
  final Narration? last;

  VoiceGuideState copyWith(
          {bool? enabled, bool? speaking, bool? paused, Narration? last}) =>
      VoiceGuideState(
        enabled: enabled ?? this.enabled,
        speaking: speaking ?? this.speaking,
        paused: paused ?? this.paused,
        last: last ?? this.last,
      );
}

class VoiceGuideController extends Notifier<VoiceGuideState> {
  NarrationService get _service => ref.read(narrationServiceProvider);
  final Set<String> _approachNarrated = {};

  @override
  VoiceGuideState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final sub = ref.watch(narrationServiceProvider).status.listen(
          (s) => state = state.copyWith(
              speaking: s == NarrationStatus.speaking,
              paused: s == NarrationStatus.paused),
        );
    ref.onDispose(sub.cancel);

    // Narasi otomatis mengikuti event lokasi (GPS/beacon/QR) dari TriggerEngine.
    ref.listen<AsyncValue<TriggerEvent>>(triggerEventsProvider, (_, next) {
      final event = next.valueOrNull;
      if (event != null) unawaited(_onTrigger(event));
    });

    // DF-01: sambutan suara saat pertama kali masuk area museum.
    ref.listen<AsyncValue<MuseumEvent>>(museumEventsProvider, (_, next) {
      final event = next.valueOrNull;
      if (event != null &&
          event.type == MuseumEventType.entered &&
          event.firstThisSession &&
          state.enabled &&
          !state.speaking &&
          !state.paused) {
        unawaited(_welcome());
      }
    });

    return VoiceGuideState(
      enabled: prefs.getBool(AppConstants.prefVoiceGuideEnabled) ?? true,
    );
  }

  Future<void> _onTrigger(TriggerEvent event) async {
    if (!state.enabled || event.source == TriggerSource.qr) return;
    final poi = event.poi;
    switch (event.type) {
      case TriggerEventType.approaching:
        // Jangan memotong narasi kedatangan, dan cukup sekali per POI.
        if (state.speaking ||
            state.paused ||
            !_approachNarrated.add(poi.id)) {
          return;
        }
        await _say(NarrationScript.approaching(poi));
      case TriggerEventType.triggered:
        final next = await _nextAfter(poi);
        await _say(NarrationScript.arrival(poi, next: next));
      case TriggerEventType.exited:
        break;
    }
  }

  Future<void> _welcome() async {
    final progress = await ref.read(progressProvider.future);
    final next = await ref
        .read(poiRepositoryProvider)
        .getRecommendedNextPoi(progress.visitedPoiIds);
    await _say(NarrationScript.museumWelcome(next: next));
  }

  Future<Poi?> _nextAfter(Poi poi) async {
    final progress = await ref.read(progressProvider.future);
    final visited = {...progress.visitedPoiIds, poi.id}.toList();
    return ref.read(poiRepositoryProvider).getRecommendedNextPoi(visited);
  }

  Future<void> _say(Narration n) async {
    state = state.copyWith(last: n);
    await _service.speak(n.parts);
  }

  /// Bacakan cerita lengkap POI (tombol "Dengar" manual, bekerja walau mode otomatis mati).
  Future<void> narratePoi(Poi poi) => _say(NarrationScript.full(poi));

  /// Bacakan perkenalan POI seperti saat tiba (dipakai di layar pemandu).
  Future<void> introducePoi(Poi poi) async =>
      _say(NarrationScript.arrival(poi, next: await _nextAfter(poi)));

  Future<void> replay() async {
    final last = state.last;
    if (last != null) await _service.speak(last.parts);
  }

  /// Jeda narasi yang sedang dibacakan (DF-03).
  Future<void> pause() => _service.pause();

  /// Lanjutkan narasi yang dijeda dari kalimat terakhir.
  Future<void> resume() => _service.resume();

  Future<void> stop() => _service.stop();

  Future<void> setEnabled(bool enabled) async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(AppConstants.prefVoiceGuideEnabled, enabled);
    state = state.copyWith(enabled: enabled);
    if (!enabled) await _service.stop();
  }

  Future<void> toggle() => setEnabled(!state.enabled);
}

final voiceGuideProvider =
    NotifierProvider<VoiceGuideController, VoiceGuideState>(
        VoiceGuideController.new);
