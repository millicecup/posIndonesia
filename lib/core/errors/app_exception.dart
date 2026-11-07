// lib/core/errors/app_exception.dart
// Jenis error aplikasi agar UI bisa menampilkan pesan yang jelas.

class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' | penyebab: $cause' : ''}';
}

/// Gagal membaca file aset (misal pois.json tidak ada).
class DataLoadException extends AppException {
  const DataLoadException(super.message, {super.cause});
}

/// Format JSON tidak sesuai model.
class DataParseException extends AppException {
  const DataParseException(super.message, {super.cause});
}

/// Masalah izin/layanan lokasi.
class LocationException extends AppException {
  const LocationException(super.message, {super.cause});
}

/// Masalah pemutaran audio.
class AudioException extends AppException {
  const AudioException(super.message, {super.cause});
}

/// Gagal mengunduh audio/foto dari Firebase Hosting.
class MediaException extends AppException {
  const MediaException(super.message, {super.cause});
}
