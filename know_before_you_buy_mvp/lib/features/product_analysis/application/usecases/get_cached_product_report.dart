import '../../domain/entities/product_report.dart';
import '../../domain/repositories/product_analysis_repository.dart';

class GetCachedProductReport {
  const GetCachedProductReport(this._repository);

  final ProductAnalysisRepository _repository;

  Future<ProductReport?> call() {
    return _repository.getLatestReport();
  }
}
