// lib/services/narration_service.dart
// Suara pemandu (Text-to-Speech bawaan Android, bahasa Indonesia) untuk Visual Tour Guide (F07)
// dan narasi POI (F03/F04). Tanpa API key, tanpa biaya, tidak butuh internet bila suara
// Indonesia sudah terpasang di HP (Setelan > Text-to-speech > Google).

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../core/utils/app_logger.dart';

abstract class NarrationService {
  /// Bacakan [parts] berurutan. Memanggil speak lagi menghentikan bacaan sebelumnya.
  Future<void> speak(List<String> parts);

  Future<void> stop();

  /// true selama sedang membacakan.
  Stream<bool> get speaking;

  void dispose();
}

class TtsNarrationService implements NarrationService {
  TtsNarrationService() {
    _tts.setStartHandler(() => _speaking.add(true));
    _tts.setCompletionHandler(() {});
    _tts.setCancelHandler(() => _speaking.add(false));
    _tts.setErrorHandler((msg) {
      AppLogger.error(_tag, 'TTS error: $msg');
      _speaking.add(false);
    });
  }

  static const _tag = 'SUARA';

  final FlutterTts _tts = FlutterTts();
  final _speaking = StreamController<bool>.broadcast();
  bool _ready = false;
  int _session = 0;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _tts.awaitSpeakCompletion(true);
    final available = await _tts.isLanguageAvailable('id-ID');
    if (available == true) {
      await _tts.setLanguage('id-ID');
    } else {
      AppLogger.error(_tag, 'Suara bahasa Indonesia belum terpasang; memakai suara bawaan HP');
    }
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  @override
  Future<void> speak(List<String> parts) async {
    await _init();
    final session = ++_session;
    await _tts.stop();
    _speaking.add(true);
    // Dibacakan per paragraf: batas panjang teks TTS Android sekitar 4000 karakter.
    for (final part in parts) {
      if (session != _session) return; // dihentikan / diganti bacaan baru
      final text = part.trim();
      if (text.isEmpty) continue;
      await _tts.speak(text);
    }
    if (session == _session) _speaking.add(false);
  }

  @override
  Future<void> stop() async {
    _session++;
    await _tts.stop();
    _speaking.add(false);
  }

  @override
  Stream<bool> get speaking => _speaking.stream;

  @override
  void dispose() {
    _tts.stop();
    _speaking.close();
  }
}
