// test/helpers/retest_fakes.dart
// Fake bersama untuk tes retest defek (Rangkuman Defek dan Retest).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jejakpos/features/media_download/state/media_download_controller.dart';
import 'package:jejakpos/features/voice_guide/state/voice_guide_controller.dart';
import 'package:jejakpos/providers/providers.dart';
import 'package:jejakpos/services/media_service.dart';
import 'package:jejakpos/services/narration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_data.dart';

class FakeNarration implements NarrationService {
  final _status = StreamController<NarrationStatus>.broadcast();
  final spoken = <List<String>>[];
  int pauses = 0;
  int resumes = 0;
  int stops = 0;

  @override
  Future<void> speak(List<String> parts) async {
    spoken.add(parts);
    _status.add(NarrationStatus.speaking);
  }

  @override
  Future<void> pause() async {
    pauses++;
    _status.add(NarrationStatus.paused);
  }

  @override
  Future<void> resume() async {
    resumes++;
    _status.add(NarrationStatus.speaking);
  }

  @override
  Future<void> stop() async {
    stops++;
    _status.add(NarrationStatus.idle);
  }

  @override
  Stream<NarrationStatus> get status => _status.stream;

  @override
  Stream<bool> get speaking =>
      _status.stream.map((s) => s == NarrationStatus.speaking);

  @override
  void dispose() => _status.close();
}

class NoDownload extends MediaDownloadController {
  @override
  Future<MediaDownloadState> build() async =>
      const MediaDownloadState(missing: 0);
}

/// Override standar: data POI dari disk, prefs mock, tanpa TTS/unduhan asli.
List<Override> baseOverrides(SharedPreferences prefs,
        {FakeNarration? narration}) =>
    [
      sharedPreferencesProvider.overrideWithValue(prefs),
      poiRepositoryProvider.overrideWithValue(buildRepository()),
      narrationServiceProvider
          .overrideWithValue(narration ?? FakeNarration()),
      mediaDownloadProvider.overrideWith(NoDownload.new),
      mediaSourceProvider
          .overrideWith((ref, args) async => BundledMedia(args.path)),
    ];
