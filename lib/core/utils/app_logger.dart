// lib/core/utils/app_logger.dart
// Logger sederhana: tampil di Debug Console + disimpan di memori untuk UI02 (bukti PB02).

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class LogEntry {
  const LogEntry({
    required this.time,
    required this.tag,
    required this.message,
  });

  final DateTime time;
  final String tag;
  final String message;

  String get timeLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  String toString() => '[$timeLabel][$tag] $message';
}

class AppLogger {
  AppLogger._();

  static const int _maxEntries = 200;
  static final List<LogEntry> _entries = <LogEntry>[];
  static final StreamController<List<LogEntry>> _controller =
      StreamController<List<LogEntry>>.broadcast();

  /// Semua log terakhir (terbaru di akhir).
  static List<LogEntry> get entries => List.unmodifiable(_entries);

  /// Stream daftar log, dipakai UI02.
  static Stream<List<LogEntry>> get stream => _controller.stream;

  static void info(String tag, String message) => _log(tag, message);

  static void warning(String tag, String message) =>
      _log(tag, 'PERINGATAN: $message');

  static void error(String tag, String message, [Object? error]) =>
      _log(tag, 'ERROR: $message${error != null ? ' ($error)' : ''}');

  static void _log(String tag, String message) {
    final entry = LogEntry(time: DateTime.now(), tag: tag, message: message);
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    // Filter di Debug Console dengan kata kunci "JejakPOS".
    debugPrint('JejakPOS $entry');
    developer.log(message, name: 'JejakPOS.$tag');
    if (!_controller.isClosed) {
      _controller.add(entries);
    }
  }

  /// Hanya untuk unit test.
  @visibleForTesting
  static void clear() => _entries.clear();
}
