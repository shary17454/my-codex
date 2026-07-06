import '../../domain/entities/market_price_snapshot.dart';
import 'price_data_source.dart';

class MockPriceDataSource implements PriceDataSource {
  const MockPriceDataSource();

  static const _products = <MarketPriceSnapshot>[
    MarketPriceSnapshot(
      productName: 'Coffee Beans',
      averagePrice: 38,
      lowestPrice: 32,
      highestPrice: 49,
      cheaperStores: ['Store A', 'Store B'],
      previousPrice: 36,
    ),
    MarketPriceSnapshot(
      productName: 'Milk',
      averagePrice: 7,
      lowestPrice: 5.5,
      highestPrice: 9,
      cheaperStores: ['Market One'],
      previousPrice: 7,
    ),
    MarketPriceSnapshot(
      productName: 'Rice',
      averagePrice: 42,
      lowestPrice: 36,
      highestPrice: 55,
      cheaperStores: ['Grocery Plus', 'Store C'],
      previousPrice: 40,
    ),
  ];

  @override
  Future<MarketPriceSnapshot?> findMarketPrices(String productName) async {
    final query = productName.trim().toLowerCase();
    if (query.isEmpty) {
      return null;
    }

    for (final product in _products) {
      final normalizedName = product.productName.toLowerCase();
      if (normalizedName.contains(query) || query.contains(normalizedName)) {
        return product;
      }
    }

    return null;
  }
}
