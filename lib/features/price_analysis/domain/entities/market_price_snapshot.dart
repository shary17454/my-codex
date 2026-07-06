class MarketPriceSnapshot {
  const MarketPriceSnapshot({
    required this.productName,
    required this.averagePrice,
    required this.lowestPrice,
    required this.highestPrice,
    required this.cheaperStores,
    this.previousPrice,
  });

  final String productName;
  final double averagePrice;
  final double lowestPrice;
  final double highestPrice;
  final List<String> cheaperStores;
  final double? previousPrice;
}
