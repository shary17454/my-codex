import '../../features/price_analysis/domain/entities/price_analysis_result.dart';

class PriceUtils {
  const PriceUtils._();

  static double differencePercent({
    required double price,
    required double marketAverage,
  }) {
    if (marketAverage == 0) {
      return 0;
    }

    return ((price - marketAverage) / marketAverage) * 100;
  }

  static PriceStatus statusFromDifference(double differencePercent) {
    if (differencePercent <= -15) {
      return PriceStatus.excellent;
    }

    if (differencePercent <= 10) {
      return PriceStatus.fair;
    }

    if (differencePercent <= 30) {
      return PriceStatus.high;
    }

    return PriceStatus.overpriced;
  }

  static PurchaseRecommendation recommendationForStatus(PriceStatus status) {
    return switch (status) {
      PriceStatus.excellent => PurchaseRecommendation.buyNow,
      PriceStatus.fair => PurchaseRecommendation.buyNow,
      PriceStatus.high => PurchaseRecommendation.wait,
      PriceStatus.overpriced => PurchaseRecommendation.doNotBuy,
    };
  }

  static bool? isFakeDiscount({
    required double detectedPrice,
    required double? originalPrice,
    required double? previousPrice,
  }) {
    if (originalPrice == null || previousPrice == null) {
      return null;
    }

    final hasAdvertisedDiscount = originalPrice > detectedPrice;
    final wasRaisedBeforeDiscount = originalPrice > previousPrice * 1.1;
    final currentPriceIsNotMeaningfullyLower =
        detectedPrice >= previousPrice * 0.95;

    return hasAdvertisedDiscount &&
        wasRaisedBeforeDiscount &&
        currentPriceIsNotMeaningfullyLower;
  }
}
