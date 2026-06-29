import 'package:flutter_test/flutter_test.dart';
import 'package:price_detector/core/utils/price_utils.dart';
import 'package:price_detector/features/price_analysis/domain/entities/price_analysis_result.dart';

void main() {
  test('calculates the price difference percent', () {
    final result = PriceUtils.differencePercent(
      price: 110,
      marketAverage: 100,
    );

    expect(result, 10);
  });

  test('returns zero difference when market average is zero', () {
    final result = PriceUtils.differencePercent(
      price: 110,
      marketAverage: 0,
    );

    expect(result, 0);
  });

  test('maps difference boundaries to price statuses', () {
    expect(PriceUtils.statusFromDifference(-15), PriceStatus.excellent);
    expect(PriceUtils.statusFromDifference(10), PriceStatus.fair);
    expect(PriceUtils.statusFromDifference(30), PriceStatus.high);
    expect(PriceUtils.statusFromDifference(31), PriceStatus.overpriced);
  });

  test('maps price statuses to purchase recommendations', () {
    expect(
      PriceUtils.recommendationForStatus(PriceStatus.excellent),
      PurchaseRecommendation.buyNow,
    );
    expect(
      PriceUtils.recommendationForStatus(PriceStatus.high),
      PurchaseRecommendation.wait,
    );
    expect(
      PriceUtils.recommendationForStatus(PriceStatus.overpriced),
      PurchaseRecommendation.doNotBuy,
    );
  });

  test('returns null fake discount when previous data is missing', () {
    final result = PriceUtils.isFakeDiscount(
      detectedPrice: 80,
      originalPrice: 100,
      previousPrice: null,
    );

    expect(result, isNull);
  });

  test('does not flag a real meaningful discount as fake', () {
    final result = PriceUtils.isFakeDiscount(
      detectedPrice: 70,
      originalPrice: 100,
      previousPrice: 90,
    );

    expect(result, isFalse);
  });
}
