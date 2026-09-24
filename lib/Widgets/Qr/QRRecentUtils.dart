class QRRecentUtils {
  QRRecentUtils._();

  static String getPreviewText(String value) {
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

    return value;
  }

  static String getTypeLabel(String value) {
    if (value.startsWith(
      'scanly://file?type=image',
    )) {
      return 'IMAGE';
    }

    if (value.startsWith(
      'scanly://file?type=video',
    )) {
      return 'VIDEO';
    }

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      return 'URL';
    }

    return 'TEXT';
  }
}