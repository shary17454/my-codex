import '../entities/price_analysis_request.dart';
import '../entities/price_analysis_result.dart';
import '../repositories/price_repository.dart';

class AnalyzePriceUseCase {
  const AnalyzePriceUseCase(this._repository);

  final PriceRepository _repository;

  Future<PriceAnalysisResult> call(PriceAnalysisRequest request) {
    return _repository.analyzePrice(request);
  }
}
