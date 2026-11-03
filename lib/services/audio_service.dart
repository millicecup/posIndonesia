// lib/services/audio_service.dart
// Pemutar narasi & Mars Pos Indonesia (F04) berbasis just_audio.

import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';

enum AudioPlaybackStatus { idle, loading, playing, paused, completed }

class AudioService {
  AudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  String? _currentAsset;
  static const _tag = 'AUDIO';

  String? get currentAsset => _currentAsset;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  Stream<AudioPlaybackStatus> get statusStream =>
      _player.playerStateStream.map((s) {
        switch (s.processingState) {
          case ProcessingState.idle:
            return AudioPlaybackStatus.idle;
          case ProcessingState.loading:
          case ProcessingState.buffering:
            return AudioPlaybackStatus.loading;
          case ProcessingState.completed:
            return AudioPlaybackStatus.completed;
          case ProcessingState.ready:
            return s.playing
                ? AudioPlaybackStatus.playing
                : AudioPlaybackStatus.paused;
        }
      });

  /// Muat file audio dari assets (tidak dimuat ulang jika sama).
  Future<void> load(String assetPath) async {
    if (_currentAsset == assetPath) return;
    try {
      await _player.setAsset(assetPath);
      _currentAsset = assetPath;
      AppLogger.info(_tag, 'Audio dimuat: $assetPath');
    } catch (e) {
      _currentAsset = null;
      throw AudioException('Audio $assetPath gagal dimuat', cause: e);
    }
  }

  /// Putar dari awal/lanjut. Catatan: play() just_audio baru selesai saat audio berhenti,
  /// jadi sengaja tidak di-await.
  Future<void> play(String assetPath) async {
    await load(assetPath);
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    unawaited(_player.play());
  }

  Future<void> pause() => _player.pause();

  Future<void> resume() async {
    if (_currentAsset == null) return;
    unawaited(_player.play());
  }

  Future<void> stop() async {
    await _player.stop();
    _currentAsset = null;
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() => _player.dispose();
}
