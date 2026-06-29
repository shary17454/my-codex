import '../../../../core/errors/app_failure.dart';
import '../../domain/repositories/product_ocr_repository.dart';
import '../datasources/mlkit_ocr_data_source.dart';

class ProductOcrRepositoryImpl implements ProductOcrRepository {
  const ProductOcrRepositoryImpl(this._dataSource);

  final MlkitOcrDataSource _dataSource;

  @override
  Future<String> extractProductName(String imagePath) async {
    final text = await _dataSource.extractText(imagePath);
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length >= 3)
        .toList();

    if (lines.isEmpty) {
      throw const AppFailure('لم يتم التعرف على اسم المنتج من الصورة.');
    }

    lines.sort((a, b) => b.length.compareTo(a.length));
    return lines.first.length > 80 ? lines.first.substring(0, 80) : lines.first;
  }
}
