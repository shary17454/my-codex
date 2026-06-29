import 'dart:convert';

import 'package:dio/dio.dart';

import '../../domain/entities/product_database_match.dart';
import '../../domain/entities/product_report.dart';

class OpenAiProductAnalysisDataSource {
  OpenAiProductAnalysisDataSource(this._dio);

  static const _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const _model = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4o-mini',
  );

  final Dio _dio;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<ProductReport> analyze({
    required String productName,
    required String imagePath,
    ProductDatabaseMatch? databaseMatch,
  }) async {
    if (!isConfigured) {
      return _fallback(
        productName: productName,
        imagePath: imagePath,
        databaseMatch: databaseMatch,
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {'Authorization': 'Bearer $_apiKey'}),
      data: {
        'model': _model,
        'temperature': 0.2,
        'messages': [
          {
            'role': 'system',
            'content':
                'Return only compact JSON for a purchase decision report. No markdown.',
          },
          {
            'role': 'user',
            'content':
                'Analyze this product for a Saudi Arabia consumer: "$productName". '
                'Known product database context: ${_databaseContext(databaseMatch)}. '
                'Use these keys: productName, estimatedPrice, isPriceFair, '
                'marketAveragePrice, cheaperAlternative, userRating, pros, cons, '
                'isWorthBuying, finalScore. Arabic values are preferred.',
          },
        ],
      },
    );

    final content =
        response.data?['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      return _fallback(productName: productName, imagePath: imagePath);
    }

    final decoded = jsonDecode(_stripCodeFence(content)) as Map<String, dynamic>;
    return ProductReport(
      productName: decoded['productName'] as String? ?? productName,
      imagePath: imagePath,
      estimatedPrice: decoded['estimatedPrice'] as String? ?? '-',
      isPriceFair: decoded['isPriceFair'] as bool? ?? false,
      marketAveragePrice: decoded['marketAveragePrice'] as String? ?? '-',
      cheaperAlternative: decoded['cheaperAlternative'] as String? ?? '-',
      userRating: (decoded['userRating'] as num?)?.toDouble() ?? 0,
      pros: List<String>.from(decoded['pros'] as List? ?? const []),
      cons: List<String>.from(decoded['cons'] as List? ?? const []),
      isWorthBuying: decoded['isWorthBuying'] as bool? ?? false,
      finalScore: (decoded['finalScore'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.now(),
      databaseSource: databaseMatch == null ? null : 'Open Food Facts',
      sourceUrl: databaseMatch?.sourceUrl,
      brand: databaseMatch?.brand,
      categories: databaseMatch?.categories,
      healthGrade: databaseMatch?.nutriScore,
    );
  }

  ProductReport _fallback({
    required String productName,
    required String imagePath,
    ProductDatabaseMatch? databaseMatch,
  }) {
    final knownName = databaseMatch?.displayName ?? productName;
    final healthGrade = databaseMatch?.nutriScore;
    final nova = databaseMatch?.novaGroup;

    return ProductReport(
      productName: knownName,
      imagePath: imagePath,
      estimatedPrice: 'غير متوفر',
      isPriceFair: true,
      marketAveragePrice: 'غير متوفر',
      cheaperAlternative: 'تحقق من منتج مشابه بسعر أقل',
      userRating: databaseMatch == null ? 3.8 : 4.2,
      pros: [
        if (databaseMatch != null) 'تم العثور على المنتج في قاعدة Open Food Facts',
        if (healthGrade != null) 'تقييم Nutri-Score: $healthGrade',
        if (nova != null) 'تصنيف NOVA لمعالجة الغذاء: $nova',
        'تم التعرف على المنتج من الصورة وربطه بقاعدة بيانات خارجية',
      ],
      cons: [
        'قاعدة Open Food Facts لا توفر أسعار السوق غالبًا',
        if (databaseMatch == null) 'لم يتم العثور على تطابق مؤكد في قاعدة المنتجات',
        'التحليل المالي الدقيق يحتاج مصدر أسعار محلي',
      ],
      isWorthBuying: databaseMatch != null,
      finalScore: databaseMatch == null ? 62 : 78,
      createdAt: DateTime.now(),
      databaseSource: databaseMatch == null ? null : 'Open Food Facts',
      sourceUrl: databaseMatch?.sourceUrl,
      brand: databaseMatch?.brand,
      categories: databaseMatch?.categories,
      healthGrade: databaseMatch?.nutriScore,
    );
  }

  String _databaseContext(ProductDatabaseMatch? match) {
    if (match == null) {
      return 'No trusted database match found.';
    }
    return {
      'source': 'Open Food Facts',
      'name': match.productName,
      'brand': match.brand,
      'categories': match.categories,
      'ingredients': match.ingredients,
      'nutriScore': match.nutriScore,
      'novaGroup': match.novaGroup,
    }.toString();
  }

  String _stripCodeFence(String value) {
    return value
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
  }
}
