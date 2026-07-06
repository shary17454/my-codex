import '../../domain/entities/product_report.dart';

class ProductReportDto {
  const ProductReportDto._();

  static ProductReport fromMap(Map<String, dynamic> map) {
    return ProductReport(
      productName: map['productName'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      estimatedPrice: map['estimatedPrice'] as String? ?? '-',
      isPriceFair: map['isPriceFair'] as bool? ?? false,
      marketAveragePrice: map['marketAveragePrice'] as String? ?? '-',
      cheaperAlternative: map['cheaperAlternative'] as String? ?? '-',
      userRating: (map['userRating'] as num?)?.toDouble() ?? 0,
      pros: List<String>.from(map['pros'] as List? ?? const []),
      cons: List<String>.from(map['cons'] as List? ?? const []),
      isWorthBuying: map['isWorthBuying'] as bool? ?? false,
      finalScore: (map['finalScore'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      databaseSource: map['databaseSource'] as String?,
      sourceUrl: map['sourceUrl'] as String?,
      brand: map['brand'] as String?,
      categories: map['categories'] as String?,
      healthGrade: map['healthGrade'] as String?,
    );
  }

  static Map<String, dynamic> toMap(ProductReport report) {
    return {
      'productName': report.productName,
      'imagePath': report.imagePath,
      'estimatedPrice': report.estimatedPrice,
      'isPriceFair': report.isPriceFair,
      'marketAveragePrice': report.marketAveragePrice,
      'cheaperAlternative': report.cheaperAlternative,
      'userRating': report.userRating,
      'pros': report.pros,
      'cons': report.cons,
      'isWorthBuying': report.isWorthBuying,
      'finalScore': report.finalScore,
      'createdAt': report.createdAt.toIso8601String(),
      'databaseSource': report.databaseSource,
      'sourceUrl': report.sourceUrl,
      'brand': report.brand,
      'categories': report.categories,
      'healthGrade': report.healthGrade,
    };
  }
}
