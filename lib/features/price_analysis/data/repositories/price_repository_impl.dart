import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/price_utils.dart';
import '../../domain/entities/price_analysis_request.dart';
import '../../domain/entities/price_analysis_result.dart';
import '../../domain/repositories/price_repository.dart';
import '../datasources/price_data_source.dart';

class PriceRepositoryImpl implements PriceRepository {
  const PriceRepositoryImpl(this._priceDataSource);

  final PriceDataSource _priceDataSource;

  @override
  Future<PriceAnalysisResult> analyzePrice(PriceAnalysisRequest request) async {
    final marketSnapshot = await _priceDataSource.findMarketPrices(
      request.productName,
    );

    if (marketSnapshot == null) {
      throw AppException(
        'No mock market data found for ${request.productName}',
      );
    }

    final differencePercent = PriceUtils.differencePercent(
      price: request.detectedPrice,
      marketAverage: marketSnapshot.averagePrice,
    );
    final status = PriceUtils.statusFromDifference(differencePercent);

    return PriceAnalysisResult(
      productName: request.productName,
      detectedPrice: request.detectedPrice,
      marketSnapshot: marketSnapshot,
      differencePercent: differencePercent,
      status: status,
      recommendation: PriceUtils.recommendationForStatus(status),
      isFakeDiscount: PriceUtils.isFakeDiscount(
        detectedPrice: request.detectedPrice,
        originalPrice: request.originalPrice,
        previousPrice: marketSnapshot.previousPrice,
      ),
    );
  }
}
