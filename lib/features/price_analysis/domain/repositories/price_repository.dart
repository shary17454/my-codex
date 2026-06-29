import '../entities/price_analysis_request.dart';
import '../entities/price_analysis_result.dart';

abstract interface class PriceRepository {
  Future<PriceAnalysisResult> analyzePrice(PriceAnalysisRequest request);
}
