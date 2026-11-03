// lib/services/qr_service.dart
// Validasi kode QR terhadap dataset -> POI yang benar (fallback F02).

import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../data/models/poi.dart';
import '../data/repositories/poi_repository.dart';

sealed class QrResult {
  const QrResult(this.rawValue);
  final String rawValue;
}

class QrValid extends QrResult {
  const QrValid(super.rawValue, this.poi);
  final Poi poi;
}

class QrInvalidFormat extends QrResult {
  const QrInvalidFormat(super.rawValue);
}

class QrNotFound extends QrResult {
  const QrNotFound(super.rawValue);
}

class QrService {
  QrService(this._poiRepository);

  final PoiRepository _poiRepository;
  static const _tag = AppConstants.logTagQr;

  /// Normalisasi: hapus spasi, huruf besar, dukung isi QR berupa URL
  /// (misal "https://.../QR-P01" -> "QR-P01").
  static String normalize(String raw) {
    var value = raw.trim().toUpperCase();
    final match = RegExp(r'QR-P\d{2}').firstMatch(value);
    if (match != null) value = match.group(0)!;
    return value;
  }

  static bool isValidFormat(String code) =>
      AppConstants.qrCodePattern.hasMatch(code);

  Future<QrResult> validate(String raw) async {
    final code = normalize(raw);
    if (!isValidFormat(code)) {
      AppLogger.warning(_tag, 'Format QR tidak dikenali: "$raw"');
      return QrInvalidFormat(raw);
    }
    final poi = await _poiRepository.getPoiByBeaconOrQr(code);
    if (poi == null || poi.qrCode.toUpperCase() != code) {
      AppLogger.warning(_tag, 'QR $code tidak terdaftar di dataset');
      return QrNotFound(raw);
    }
    AppLogger.info(_tag, 'QR $code valid -> ${poi.id} ${poi.name}');
    return QrValid(raw, poi);
  }
}
