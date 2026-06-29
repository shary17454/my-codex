import '../../domain/entities/product_report.dart';
import '../../domain/repositories/product_analysis_repository.dart';
import '../datasources/open_food_facts_data_source.dart';
import '../datasources/openai_product_analysis_data_source.dart';
import '../datasources/product_report_local_data_source.dart';

class ProductAnalysisRepositoryImpl implements ProductAnalysisRepository {
  const ProductAnalysisRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.openFoodFactsDataSource,
  });

  final OpenAiProductAnalysisDataSource remoteDataSource;
  final ProductReportLocalDataSource localDataSource;
  final OpenFoodFactsDataSource openFoodFactsDataSource;

  @override
  Future<ProductReport> analyzeProduct({
    required String productName,
    required String imagePath,
  }) async {
    final databaseMatch = await openFoodFactsDataSource.searchByName(
      productName,
    );
    final report = await remoteDataSource.analyze(
      productName: databaseMatch?.displayName ?? productName,
      imagePath: imagePath,
      databaseMatch: databaseMatch,
    );
    await saveReport(report);
    return report;
  }

  @override
  Future<ProductReport?> getLatestReport() {
    return localDataSource.getLatest();
  }

  @override
  Future<void> saveReport(ProductReport report) {
    return localDataSource.saveLatest(report);
  }
}
