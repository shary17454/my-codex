import '../entities/product_report.dart';

abstract interface class ProductAnalysisRepository {
  Future<ProductReport> analyzeProduct({
    required String productName,
    required String imagePath,
  });

  Future<ProductReport?> getLatestReport();

  Future<void> saveReport(ProductReport report);
}
