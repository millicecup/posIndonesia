// lib/services/audio_service.dart
// Pemutar narasi & Mars Pos Indonesia (F04) berbasis just_audio.

import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/app_logger.dart';
import 'media_service.dart';

enum AudioPlaybackStatus { idle, loading, playing, paused, completed }

class AudioService {
  AudioService({required MediaService media, AudioPlayer? player})
      : _media = media,
        _player = player ?? AudioPlayer();

  final MediaService _media;
  final AudioPlayer _player;
  String? _currentAsset;

  // Naik saat stop(): unduhan yang selesai setelah layar ditutup tidak diputar.
  int _loadGeneration = 0;
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

  /// Muat audio dari aset, cache, atau Hosting (tidak dimuat ulang jika sama).
  Future<void> load(String assetPath) async {
    if (_currentAsset == assetPath) return;
    final generation = _loadGeneration;
    final source = await _media.resolve(assetPath);
    if (generation != _loadGeneration) return;
    if (source == null) {
      throw const AudioException(
          'Audio belum tersedia. Periksa koneksi internet, lalu coba lagi.');
    }
    try {
      switch (source) {
        case BundledMedia(assetPath: final bundledPath):
          await _player.setAsset(bundledPath);
        case CachedMedia(:final file):
          await _player.setFilePath(file.path);
        case RemoteMedia(:final uri):
          await _player.setUrl(uri.toString());
      }
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
    if (_currentAsset != assetPath) return;
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
    _loadGeneration++;
    await _player.stop();
    _currentAsset = null;
  }

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() => _player.dispose();
}
