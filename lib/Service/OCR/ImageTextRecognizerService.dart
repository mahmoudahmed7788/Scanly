import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImageTextRecognizerService {
  ImageTextRecognizerService._();

  static Future<String> extractText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    final TextRecognizer textRecognizer = TextRecognizer(
      script: TextRecognitionScript.latin,
    );

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      return recognizedText.text.trim();
    } finally {
      await textRecognizer.close();
    }
  }
}