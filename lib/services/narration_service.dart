// lib/services/narration_service.dart
// Suara pemandu (Text-to-Speech bawaan Android, bahasa Indonesia) untuk Visual Tour Guide (F07)
// dan narasi POI (F03/F04). Tanpa API key, tanpa biaya, tidak butuh internet bila suara
// Indonesia sudah terpasang di HP (Setelan > Text-to-speech > Google).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/utils/app_logger.dart';

/// Memilih suara bahasa Indonesia dari hasil `FlutterTts.getVoices`
/// (list of map `{name, locale}`). Suara offline/lokal diutamakan. null bila tidak ada.
@visibleForTesting
Map<String, String>? pickIndonesianVoice(Object? voices) {
  if (voices is! List) return null;
  final indo = RegExp(r'^(id|in|ind)([-_]|$)', caseSensitive: false);
  final candidates = <Map<String, String>>[];
  for (final v in voices) {
    if (v is! Map) continue;
    final name = v['name']?.toString();
    final locale = v['locale']?.toString();
    if (name == null || locale == null || !indo.hasMatch(locale)) continue;
    candidates.add({'name': name, 'locale': locale});
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    int score(Map<String, String> v) =>
        (v['name']!.toLowerCase().contains('network') ? 1 : 0);
    return score(a).compareTo(score(b));
  });
  return candidates.first;
}

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
  int _session = 0;

  /// Satu Future bersama: pemanggil speak() yang datang bersamaan (mis. "mendekati" lalu
  /// "tiba") menunggu bahasa Indonesia selesai diset, tidak langsung bicara dengan suara
  /// bawaan HP (sering bahasa Inggris).
  Future<void>? _init;

  /// Kode bahasa Indonesia yang dipakai berbagai engine TTS.
  static const _languageCandidates = ['id-ID', 'id', 'in-ID', 'ind-IDN'];
  static const _googleEngine = 'com.google.android.tts';

  Future<void> _ensureReady() {
    return _init ??= _configure().then((ok) {
      // Belum berhasil (engine belum siap / suara belum terpasang): coba lagi lain kali.
      if (!ok) _init = null;
    }).catchError((Object e) {
      AppLogger.error(_tag, 'Gagal menyiapkan TTS: $e');
      _init = null;
    });
  }

  /// Mengunci TTS ke bahasa Indonesia. Mengembalikan true bila berhasil.
  Future<bool> _configure() async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);

    var ok = await _setIndonesian();
    if (!ok && _isAndroid) {
      // Engine bawaan HP (mis. Samsung) kadang tidak punya suara Indonesia; Google punya.
      try {
        final engines = await _tts.getEngines;
        if (engines is List && engines.contains(_googleEngine)) {
          await _tts.setEngine(_googleEngine);
          ok = await _setIndonesian();
        }
      } catch (e) {
        AppLogger.error(_tag, 'Gagal beralih ke engine Google: $e');
      }
    }
    if (!ok) {
      AppLogger.error(_tag,
          'Suara bahasa Indonesia belum terpasang; pasang di Setelan > Text-to-speech');
    }
    return ok;
  }

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> _setIndonesian() async {
    var languageSet = false;
    for (final code in _languageCandidates) {
      try {
        final r = await _tts.setLanguage(code);
        if (r == 1 || r == true) {
          languageSet = true;
          break;
        }
      } catch (_) {
        // coba kode berikutnya
      }
    }

    // setLanguage saja kadang tetap memakai suara default; pilih suara id eksplisit.
    try {
      final voice = pickIndonesianVoice(await _tts.getVoices);
      if (voice != null) {
        await _tts.setVoice(voice);
        return true;
      }
    } catch (_) {
      // getVoices tidak didukung di platform ini
    }
    return languageSet;
  }

  @override
  Future<void> speak(List<String> parts) async {
    await _ensureReady();
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
