import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';


class TesseractOcr {
  static const String tessDataConfig =
      'assets/tessdata_config.json';

  static const String tessDataPath =
      'assets/tessdata';

  static const MethodChannel _channel =
      MethodChannel('tesseract_ocr');

  static Future<String> extractText(
    String imagePath, {
    OCRConfig? config,
    String language = 'eng',
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

    String? tessDataDirectory;

    if (actualConfig.engine != OCREngine.vision) {
      tessDataDirectory = await _loadTessData();
    }

    final Map<String, dynamic> args = {
      'imagePath': imagePath,
      'tessData': tessDataDirectory,
      'language': actualConfig.language,
    };

    try {
      final String? result =
          await _channel.invokeMethod<String>(
        'extractText',
        args,
      );

      return result ?? '';
    } on MissingPluginException {
      throw Exception(
        'Tesseract OCR plugin is not registered. '
        'Please completely stop the app and run it again.',
      );
    } on PlatformException catch (e) {
      throw Exception(
        'Tesseract OCR error: ${e.message ?? e.code}',
      );
    }
  }

  static Future<String> _loadTessData() async {
    final Directory appDirectory =
        await getApplicationDocumentsDirectory();

    final String tessdataDirectory =
        join(appDirectory.path, 'tessdata');

    final Directory directory =
        Directory(tessdataDirectory);

    if (!await directory.exists()) {
      await directory.create(
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
      tessDataConfig,
    );

    final Map<String, dynamic> files =
        jsonDecode(config);

    final List<dynamic> fileList =
        files['files'] as List<dynamic>;

    for (final dynamic item in fileList) {
      final String fileName = item.toString();

      final String assetPath =
          join(
        tessDataPath,
        fileName,
      );

      final String destinationPath =
          join(
        tessdataDirectory,
        fileName,
      );

      final File destinationFile =
          File(destinationPath);

      if (await destinationFile.exists()) {
        continue;
      }

      final ByteData data =
          await rootBundle.load(assetPath);

      final Uint8List bytes =
          data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await destinationFile.writeAsBytes(
        bytes,
        flush: true,
      );
    }
  }
}