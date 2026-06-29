class OcrResult {
  const OcrResult({
    required this.rawText,
    this.productName,
    this.price,
  });

  final String rawText;
  final String? productName;
  final double? price;
}
