import '../../domain/entities/market_price_snapshot.dart';

abstract interface class PriceDataSource {
  Future<MarketPriceSnapshot?> findMarketPrices(String productName);
}
