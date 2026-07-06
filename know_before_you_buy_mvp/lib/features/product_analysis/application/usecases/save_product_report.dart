import '../../domain/entities/product_report.dart';
import '../../domain/repositories/product_analysis_repository.dart';

class SaveProductReport {
  const SaveProductReport(this._repository);

  final ProductAnalysisRepository _repository;

  Future<void> call(ProductReport report) {
    return _repository.saveReport(report);
  }
}
