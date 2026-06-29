import 'market_price_snapshot.dart';

enum PriceStatus {
  excellent,
  fair,
  high,
  overpriced,
}

enum PurchaseRecommendation {
  buyNow,
  wait,
  doNotBuy,
}

class PriceAnalysisResult {
  const PriceAnalysisResult({
    required this.productName,
    required this.detectedPrice,
    required this.marketSnapshot,
    required this.differencePercent,
    required this.status,
    required this.recommendation,
    required this.isFakeDiscount,
  });

  final String productName;
  final double detectedPrice;
  final MarketPriceSnapshot marketSnapshot;
  final double differencePercent;
  final PriceStatus status;
  final PurchaseRecommendation recommendation;
  final bool? isFakeDiscount;
}
