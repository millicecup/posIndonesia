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

enum NarrationStatus { idle, speaking, paused }

/// Memecah naskah menjadi kalimat agar narasi bisa dijeda lalu dilanjutkan dari
/// kalimat terakhir (DF-03), bukan diulang dari awal. Singkatan bergaya
/// "R. Dijar" dan angka desimal "1.5" tidak dipotong.
@visibleForTesting
List<String> splitIntoSentences(List<String> parts) {
  final boundary =
      RegExp(r'(?<=[a-z0-9)À-ɏ][.!?])\s+(?=[A-Z"“])');
  return [
    for (final part in parts)
      for (final sentence in part.trim().split(boundary))
        if (sentence.trim().isNotEmpty) sentence.trim(),
  ];
}

/// Antrean kalimat yang bisa dijeda/dilanjutkan. Terpisah dari plugin TTS agar
/// mudah di-test. [speakOne] harus selesai saat kalimat selesai dibacakan
/// (atau dihentikan lewat [stopEngine]).
class ResumableSpeechQueue {
  ResumableSpeechQueue({required this.speakOne, required this.stopEngine});

  final Future<void> Function(String text) speakOne;
  final Future<void> Function() stopEngine;

  final _status = StreamController<NarrationStatus>.broadcast();
  NarrationStatus _current = NarrationStatus.idle;
  List<String> _queue = const [];
  int _index = 0;
  int _session = 0;

  NarrationStatus get current => _current;
  Stream<NarrationStatus> get status => _status.stream;

  /// Kalimat yang sedang/akan dibacakan berikutnya (untuk test & UI).
  int get position => _index;
  int get length => _queue.length;

  void _set(NarrationStatus s) {
    _current = s;
    if (!_status.isClosed) _status.add(s);
  }

  /// Mulai naskah baru. [prepare] (mis. menyiapkan bahasa Indonesia) dipanggil
  /// setelah bacaan lama dihentikan; false = batal membaca.
  Future<void> start(List<String> parts,
      {Future<bool> Function()? prepare}) async {
    final session = ++_session;
    await stopEngine();
    if (prepare != null && !await prepare()) {
      if (session == _session) _set(NarrationStatus.idle);
      return;
    }
    if (session != _session) return;
    _queue = splitIntoSentences(parts);
    _index = 0;
    await _run(session);
  }

  Future<void> _run(int session) async {
    _set(NarrationStatus.speaking);
    while (_index < _queue.length) {
      if (session != _session) return;
      await speakOne(_queue[_index]);
      // Dihentikan/dijeda di tengah kalimat: posisi tetap di kalimat ini.
      if (session != _session) return;
      _index++;
    }
    _queue = const [];
    _index = 0;
    _set(NarrationStatus.idle);
  }

  /// Jeda: hentikan suara, ingat kalimat yang sedang dibacakan.
  Future<void> pause() async {
    if (_current != NarrationStatus.speaking) return;
    _session++;
    _set(NarrationStatus.paused);
    await stopEngine();
  }

  /// Lanjutkan dari kalimat yang terpotong saat dijeda.
  Future<void> resume() async {
    if (_current != NarrationStatus.paused || _index >= _queue.length) return;
    await _run(++_session);
  }

  Future<void> stop() async {
    _session++;
    _queue = const [];
    _index = 0;
    _set(NarrationStatus.idle);
    await stopEngine();
  }

  /// Engine melaporkan error: anggap bacaan berhenti.
  void markIdle() {
    _session++;
    _set(NarrationStatus.idle);
  }

  void dispose() => _status.close();
}

abstract class NarrationService {
  /// Bacakan [parts] berurutan. Memanggil speak lagi menghentikan bacaan sebelumnya.
  Future<void> speak(List<String> parts);

  /// Jeda bacaan; [resume] melanjutkan dari kalimat yang terpotong.
  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  /// Status bacaan (idle / speaking / paused).
  Stream<NarrationStatus> get status;

  /// true selama sedang membacakan.
  Stream<bool> get speaking;

  void dispose();
}

class TtsNarrationService implements NarrationService {
  TtsNarrationService() {
    _queue = ResumableSpeechQueue(
      speakOne: (text) async {
        await _tts.speak(text);
      },
      stopEngine: () async {
        await _tts.stop();
      },
    );
    _tts.setCompletionHandler(() {});
    _tts.setErrorHandler((msg) {
      AppLogger.error(_tag, 'TTS error: $msg');
      _queue.markIdle();
    });
  }

  static const _tag = 'SUARA';

  final FlutterTts _tts = FlutterTts();
  late final ResumableSpeechQueue _queue;

  /// Satu Future bersama: pemanggil speak() yang datang bersamaan (mis. "mendekati" lalu
  /// "tiba") menunggu bahasa Indonesia selesai diset, tidak langsung bicara dengan suara
  /// bawaan HP (sering bahasa Inggris).
  Future<bool>? _init;

  /// Kode bahasa Indonesia yang dipakai berbagai engine TTS.
  static const _languageCandidates = ['id-ID', 'id', 'in-ID', 'ind-IDN'];
  static const _googleEngine = 'com.google.android.tts';

  Future<bool> _ensureReady() {
    return _init ??= _configure().then((ok) {
      // Belum berhasil (engine belum siap / suara belum terpasang): coba lagi lain kali.
      if (!ok) _init = null;
      return ok;
    }).catchError((Object e) {
      AppLogger.error(_tag, 'Gagal menyiapkan TTS: $e');
      _init = null;
      return false;
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
      var voice = pickIndonesianVoice(await _tts.getVoices);
      // Browser voices can arrive asynchronously after the first request.
      for (var attempt = 0; kIsWeb && voice == null && attempt < 3; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        voice = pickIndonesianVoice(await _tts.getVoices);
      }
      if (voice != null) {
        await _tts.setVoice(voice);
        return true;
      }
    } catch (_) {
      // getVoices tidak didukung di platform ini
    }
    // Web setLanguage can succeed even when no matching voice is installed.
    return !kIsWeb && languageSet;
  }

  @override
  Future<void> speak(List<String> parts) =>
      _queue.start(parts, prepare: _ensureReady);

  @override
  Future<void> pause() => _queue.pause();

  @override
  Future<void> resume() => _queue.resume();

  @override
  Future<void> stop() => _queue.stop();

  @override
  Stream<NarrationStatus> get status => _queue.status;

  @override
  Stream<bool> get speaking =>
      _queue.status.map((s) => s == NarrationStatus.speaking);

  @override
  void dispose() {
    _tts.stop();
    _queue.dispose();
  }
}
