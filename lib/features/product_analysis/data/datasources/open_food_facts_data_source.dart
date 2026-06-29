import 'package:dio/dio.dart';

import '../../domain/entities/product_database_match.dart';

class OpenFoodFactsDataSource {
  const OpenFoodFactsDataSource(this._dio);

  final Dio _dio;

  Future<ProductDatabaseMatch?> searchByName(String productName) async {
    final query = productName.trim();
    if (query.length < 3) {
      return null;
    }

    final response = await _dio.get<Map<String, dynamic>>(
      'https://world.openfoodfacts.org/cgi/search.pl',
      queryParameters: {
        'search_terms': query,
        'search_simple': 1,
        'action': 'process',
        'json': 1,
        'page_size': 1,
        'fields': [
          'code',
          'product_name',
          'brands',
          'image_front_url',
          'categories',
          'ingredients_text',
          'nutriscore_grade',
          'nova_group',
          'url',
        ].join(','),
      },
    );

    final products = response.data?['products'];
    if (products is! List || products.isEmpty) {
      return null;
    }

    final product = products.first;
    if (product is! Map) {
      return null;
    }

    final name = product['product_name'] as String?;
    if (name == null || name.trim().isEmpty) {
      return null;
    }

    return ProductDatabaseMatch(
      productName: name.trim(),
      brand: _clean(product['brands']),
      imageUrl: _clean(product['image_front_url']),
      categories: _clean(product['categories']),
      ingredients: _clean(product['ingredients_text']),
      nutriScore: _clean(product['nutriscore_grade'])?.toUpperCase(),
      novaGroup: (product['nova_group'] as num?)?.toInt(),
      sourceUrl: _clean(product['url']),
    );
  }

  String? _clean(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
