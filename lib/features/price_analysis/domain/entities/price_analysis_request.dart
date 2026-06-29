class PriceAnalysisRequest {
  const PriceAnalysisRequest({
    required this.productName,
    required this.detectedPrice,
    this.originalPrice,
  });

  final String productName;
  final double detectedPrice;
  final double? originalPrice;
}
