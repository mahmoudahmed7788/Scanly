
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class TesseractOcr {
  static const MethodChannel _channel =
      MethodChannel('tesseract_ocr');

  // اللغات اللي Scanly بيدعمها
  static const List<String> _languages = [
    'ara',
    'eng',
    'fra',
    'deu',
    'spa',
  ];

  static Future<String> extractText(
    String imagePath, {
    required String language,
  }) async {
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      throw Exception(
        'Image file does not exist: $imagePath',
      );
    }

    final tessDataPath =
        await _prepareTessData();

    // لو المستخدم اختار ara+eng
    // نتأكد إن اللغتين موجودين.
    final requestedLanguages =
        language.split('+');

    for (final lang in requestedLanguages) {
      final trimmedLang = lang.trim();

      if (trimmedLang.isEmpty) {
        continue;
      }

      if (!_languages.contains(trimmedLang)) {
        throw Exception(
          'Unsupported OCR language: $trimmedLang',
        );
      }

      final trainedDataFile = File(
        path.join(
          tessDataPath,
          'tessdata',
          '$trimmedLang.traineddata',
        ),
      );

      if (!await trainedDataFile.exists()) {
        throw Exception(
          'Tesseract language file not found: '
          '${trainedDataFile.path}',
        );
      }
    }

    final args = <String, dynamic>{
      'imagePath': imagePath,
      'tessData': tessDataPath,
      'language': language,
      'engine': 'tesseract',
    };

    print('========== TESSERACT OCR ==========');
    print('Image: $imagePath');
    print('Language: $language');
    print('TessData: $tessDataPath');

    final result =
        await _channel.invokeMethod<String>(
      'extractText',
      args,
    );

    return result ?? '';
  }

  static Future<String> _prepareTessData() async {
    final appDirectory =
        await getApplicationDocumentsDirectory();

    final tessdataDirectory = Directory(
      path.join(
        appDirectory.path,
        'tessdata',
      ),
    );

    if (!await tessdataDirectory.exists()) {
      await tessdataDirectory.create(
        recursive: true,
      );
    }

    // بننسخ اللغات المطلوبة فقط.
    for (final language in _languages) {
      await _copyLanguageFile(
        language,
        tessdataDirectory,
      );
    }

    return appDirectory.path;
  }

  static Future<void> _copyLanguageFile(
    String language,
    Directory tessdataDirectory,
  ) async {
    final fileName =
        '$language.traineddata';

    final assetPath =
        'assets/tessdata/$fileName';

    final destinationFile = File(
      path.join(
        tessdataDirectory.path,
        fileName,
      ),
    );

    // لو موجود بالفعل مش محتاجين ننسخه تاني.
    if (await destinationFile.exists()) {
      return;
    }

    try {
      final ByteData data =
          await rootBundle.load(assetPath);

      final bytes =
          data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await destinationFile.writeAsBytes(
        bytes,
        flush: true,
      );

      print(
        'Tesseract copied: $fileName',
      );
    } catch (e) {
      throw Exception(
        'Tesseract language file missing: '
        '$assetPath\n'
        'Error: $e',
      );
    }
  }
}
