import 'dart:convert';

class QRPreviewUtils {
  QRPreviewUtils._();

  static String itemId(String value) {
    return 'qr_${base64Url.encode(
      utf8.encode(value),
    )}';
  }

  static String getSubtitle(String value) {
    if (value.startsWith(
      'scanly://file?type=image',
    )) {
      return 'Image QR Code';
    }

    if (value.startsWith(
      'scanly://file?type=video',
    )) {
      return 'Video QR Code';
    }

    if (value.length > 45) {
      return '${value.substring(0, 45)}...';
    }

    return value;
  }
}