import '../../domain/repositories/product_ocr_repository.dart';

class ExtractProductName {
  const ExtractProductName(this._repository);

  final ProductOcrRepository _repository;

  Future<String> call(String imagePath) {
    return _repository.extractProductName(imagePath);
  }
}
