import '../../domain/entities/product_report.dart';
import '../../domain/repositories/product_analysis_repository.dart';

class AnalyzeProduct {
  const AnalyzeProduct(this._repository);

  final ProductAnalysisRepository _repository;

  Future<ProductReport> call({
    required String productName,
    required String imagePath,
  }) {
    return _repository.analyzeProduct(
      productName: productName,
      imagePath: imagePath,
    );
  }
}
