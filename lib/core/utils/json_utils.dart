// lib/core/utils/json_utils.dart
// Helper parsing JSON yang memberi pesan error jelas.

import '../errors/app_exception.dart';

T readRequired<T>(Map<String, dynamic> json, String key, {String? context}) {
  final value = json[key];
  if (value == null) {
    throw DataParseException(
        'Field wajib "$key" tidak ada${context != null ? ' pada $context' : ''}');
  }
  if (value is! T) {
    throw DataParseException(
        'Field "$key" bertipe ${value.runtimeType}, seharusnya $T'
        '${context != null ? ' pada $context' : ''}');
  }
  return value;
}

double readDouble(Map<String, dynamic> json, String key, {String? context}) {
  final value = readRequired<num>(json, key, context: context);
  return value.toDouble();
}

double? readNullableDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw DataParseException('Field "$key" harus angka atau null');
}

List<String> readStringList(Map<String, dynamic> json, String key,
    {String? context}) {
  final value = readRequired<List<dynamic>>(json, key, context: context);
  return value.map((e) => e.toString()).toList(growable: false);
}

/// Perbandingan list sederhana (nama beda dari listEquals milik Flutter agar tidak bentrok).
bool sameList<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
