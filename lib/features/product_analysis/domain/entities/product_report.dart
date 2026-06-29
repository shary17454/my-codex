class ProductReport {
  const ProductReport({
    required this.productName,
    required this.imagePath,
    required this.estimatedPrice,
    required this.isPriceFair,
    required this.marketAveragePrice,
    required this.cheaperAlternative,
    required this.userRating,
    required this.pros,
    required this.cons,
    required this.isWorthBuying,
    required this.finalScore,
    required this.createdAt,
    this.databaseSource,
    this.sourceUrl,
    this.brand,
    this.categories,
    this.healthGrade,
  });

  final String productName;
  final String imagePath;
  final String estimatedPrice;
  final bool isPriceFair;
  final String marketAveragePrice;
  final String cheaperAlternative;
  final double userRating;
  final List<String> pros;
  final List<String> cons;
  final bool isWorthBuying;
  final int finalScore;
  final DateTime createdAt;
  final String? databaseSource;
  final String? sourceUrl;
  final String? brand;
  final String? categories;
  final String? healthGrade;
}
