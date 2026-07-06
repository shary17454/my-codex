class ProductDatabaseMatch {
  const ProductDatabaseMatch({
    required this.productName,
    this.brand,
    this.imageUrl,
    this.categories,
    this.ingredients,
    this.nutriScore,
    this.novaGroup,
    this.sourceUrl,
  });

  final String productName;
  final String? brand;
  final String? imageUrl;
  final String? categories;
  final String? ingredients;
  final String? nutriScore;
  final int? novaGroup;
  final String? sourceUrl;

  String get displayName {
    if (brand == null || brand!.isEmpty) {
      return productName;
    }
    return '$productName - $brand';
  }
}
