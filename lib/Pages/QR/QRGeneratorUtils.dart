import 'dart:convert';

class QRGeneratorUtils {
  QRGeneratorUtils._();

  static String itemId(String value) {
    return 'qr_${base64Url.encode(
      utf8.encode(value),
    )}';
  }

  static String getSubtitle({
    required String value,
    required String type,
  }) {
    if (type == 'image') {
      return 'Image QR Code';
    }

    if (type == 'video') {
      return 'Video QR Code';
    }

    return value.length > 45
        ? value.substring(0, 45)
        : value;
  }

  static String buildFileQRValue({
    required String type,
    required String path,
  }) {
    return 'scanly://file?type=$type&path=$path';
  }

  static String getDisplayValue({
    required String qrData,
    String? filePath,
  }) {
    return filePath ?? qrData;
  }
}