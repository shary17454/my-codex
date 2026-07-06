import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MlkitOcrDataSource {
  Future<String> extractText(String imagePath) async {
    final recognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      await recognizer.close();
    }
  }
}
