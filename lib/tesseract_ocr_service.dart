import 'package:flutter/services.dart';

class TesseractOcr {
  static const MethodChannel _channel =
      MethodChannel('tesseract_ocr');

  static Future<String> extractText(
    String imagePath, {
    String language = 'eng',
    Map<String, dynamic>? options,
  }) async {
    final result = await _channel.invokeMethod<String>(
      'extractText',
      {
        'imagePath': imagePath,
        'tessData': '', // هنظبطه بعدين
        'language': language,
        'options': options ?? {},
      },
    );

    return result ?? '';
  }
}