
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'package:tesseract_ocr/ocr_engine_config.dart';

class TesseractOcr {
  static const String TESS_DATA_CONFIG =
      'assets/tessdata_config.json';

  static const String TESS_DATA_PATH =
      'assets/tessdata';

  static const MethodChannel _channel =
      MethodChannel('tesseract_ocr');

  static Future<String> extractText(
    String imagePath, {
    OCRConfig? config,
    required String language,
  }) async {
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      throw Exception(
        'Image file does not exist: $imagePath',
      );
    }

    final actualConfig = config ??
        OCRConfig(
          language: language,
          engine: OCREngine.tesseract,
        );

    final tessDataPath =
        await _loadTessData();

    final Map<String, dynamic> args = {
      'imagePath': imagePath,

      // Important:
      // Android expects the parent directory
      // containing "tessdata".
      'tessData': tessDataPath,

      // Use the language selected by the user.
      'language': language,

      'engine': actualConfig.engine
          .toString()
          .split('.')
          .last,
    };

    if (actualConfig.options != null) {
      args.addAll(
        actualConfig.options!,
      );
    }

    print(
      'Tesseract OCR',
    );

    print(
      'Image: $imagePath',
    );

    print(
      'Language: $language',
    );

    print(
      'TessData: $tessDataPath',
    );

    final String extractedText =
        await _channel.invokeMethod<String>(
          'extractText',
          args,
        ) ??
        '';

    return extractedText;
  }

  static Future<String> _loadTessData() async {
    final Directory appDirectory =
        await getApplicationDocumentsDirectory();

    final String tessdataDirectory =
        join(
      appDirectory.path,
      'tessdata',
    );

    final Directory tessdata =
        Directory(tessdataDirectory);

    if (!await tessdata.exists()) {
      await tessdata.create(
        recursive: true,
      );
    }

    await _copyTessDataToAppDocumentsDirectory(
      tessdataDirectory,
    );

    return appDirectory.path;
  }

  static Future<void>
      _copyTessDataToAppDocumentsDirectory(
    String tessdataDirectory,
  ) async {
    final String config =
        await rootBundle.loadString(
      TESS_DATA_CONFIG,
    );

    final Map<String, dynamic> files =
        jsonDecode(config);

    final List<dynamic> fileList =
        files['files'] ?? [];

    for (final dynamic item in fileList) {
      final String file =
          item.toString();

      final String destinationPath =
          join(
        tessdataDirectory,
        file,
      );

      final File destinationFile =
          File(destinationPath);

      // Don't copy the file again if it
      // already exists.
      if (await destinationFile.exists()) {
        continue;
      }

      final String assetPath =
          join(
        TESS_DATA_PATH,
        file,
      );

      try {
        final ByteData data =
            await rootBundle.load(
          assetPath,
        );

        final Uint8List bytes =
            data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        await destinationFile.writeAsBytes(
          bytes,
          flush: true,
        );
      } catch (e) {
        throw Exception(
          'Failed to copy Tesseract file '
          '"$file": $e',
        );
      }
    }
  }
}
