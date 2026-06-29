import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/ocr_result.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../services/ocr_text_parser.dart';

class MlKitOcrRepository implements OcrRepository {
  MlKitOcrRepository({
    TextRecognizer? textRecognizer,
    OcrTextParser? parser,
  })  : _textRecognizer = textRecognizer ??
            TextRecognizer(script: TextRecognitionScript.latin),
        _parser = parser ?? const OcrTextParser();

  final TextRecognizer _textRecognizer;
  final OcrTextParser _parser;

  @override
  Future<OcrResult> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return _parser.parse(recognizedText.text);
    } catch (error) {
      throw AppException('OCR extraction failed', cause: error);
    }
  }

  Future<void> dispose() {
    return _textRecognizer.close();
  }
}
