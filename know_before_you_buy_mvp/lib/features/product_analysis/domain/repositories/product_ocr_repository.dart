abstract interface class ProductOcrRepository {
  Future<String> extractProductName(String imagePath);
}
