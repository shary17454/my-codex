import '../entities/ocr_result.dart';

abstract interface class OcrRepository {
  Future<OcrResult> extractTextFromImage(String imagePath);
}
