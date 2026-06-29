import 'package:flutter_test/flutter_test.dart';
import 'package:price_detector/core/errors/app_exception.dart';
import 'package:price_detector/features/price_analysis/data/datasources/mock_price_data_source.dart';
import 'package:price_detector/features/price_analysis/data/repositories/price_repository_impl.dart';
import 'package:price_detector/features/price_analysis/domain/entities/price_analysis_request.dart';
import 'package:price_detector/features/price_analysis/domain/entities/price_analysis_result.dart';

void main() {
  late PriceRepositoryImpl repository;

  setUp(() {
    repository = const PriceRepositoryImpl(MockPriceDataSource());
  });

  test('classifies a price below market as excellent', () async {
    final result = await repository.analyzePrice(
      const PriceAnalysisRequest(
        productName: 'Coffee Beans',
        detectedPrice: 32,
      ),
    );

    expect(result.status, PriceStatus.excellent);
    expect(result.recommendation, PurchaseRecommendation.buyNow);
    expect(result.marketSnapshot.lowestPrice, 32);
  });

  test('classifies a price far above market as overpriced', () async {
    final result = await repository.analyzePrice(
      const PriceAnalysisRequest(
        productName: 'Milk',
        detectedPrice: 10,
      ),
    );

    expect(result.status, PriceStatus.overpriced);
    expect(result.recommendation, PurchaseRecommendation.doNotBuy);
  });

  test('detects a fake discount when previous price was lower', () async {
    final result = await repository.analyzePrice(
      const PriceAnalysisRequest(
        productName: 'Rice',
        detectedPrice: 40,
        originalPrice: 55,
      ),
    );

    expect(result.isFakeDiscount, isTrue);
  });

  test('throws an app exception when mock data does not exist', () async {
    expect(
      () => repository.analyzePrice(
        const PriceAnalysisRequest(
          productName: 'Unknown Product',
          detectedPrice: 25,
        ),
      ),
      throwsA(isA<AppException>()),
    );
  });
}
