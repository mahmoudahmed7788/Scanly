class QRFavoritesUtils {
  QRFavoritesUtils._();

  static String getTypeLabel(String value) {
    final lower = value.toLowerCase();

    if (lower.startsWith('image:') ||
        lower.startsWith('image://') ||
        lower.startsWith('image/')) {
      return 'IMAGE';
    }

    if (lower.startsWith('video:') ||
        lower.startsWith('video://') ||
        lower.startsWith('video/')) {
      return 'VIDEO';
    }

    if (lower.startsWith('http://') ||
        lower.startsWith('https://')) {
      return 'URL';
    }

    return 'TEXT';
  }

  static String getPreviewText(String value) {
    final lower = value.toLowerCase();

    if (lower.startsWith('image:') ||
        lower.startsWith('image://') ||
        lower.startsWith('image/')) {
      return 'Image QR Code';
    }

    if (lower.startsWith('video:') ||
        lower.startsWith('video://') ||
        lower.startsWith('video/')) {
      return 'Video QR Code';
    }

    return value;
  }

  static String shortenText(String value) {
    final text = getPreviewText(value);

    if (text.length <= 55) {
      return text;
    }

    return '${text.substring(0, 55)}...';
  }
}