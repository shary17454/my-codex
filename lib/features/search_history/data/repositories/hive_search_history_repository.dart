import 'package:hive/hive.dart';

import '../../../price_analysis/domain/entities/market_price_snapshot.dart';
import '../../../price_analysis/domain/entities/price_analysis_result.dart';
import '../../domain/entities/search_history_item.dart';
import '../../domain/repositories/search_history_repository.dart';

class HiveSearchHistoryRepository implements SearchHistoryRepository {
  const HiveSearchHistoryRepository(this._box);

  static const boxName = 'search_history';

  final Box<dynamic> _box;

  @override
  Future<List<SearchHistoryItem>> getAll() async {
    final items = _box.values
        .whereType<Map<dynamic, dynamic>>()
        .map(_fromMap)
        .whereType<SearchHistoryItem>()
        .toList(growable: false);

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  @override
  Future<void> save(SearchHistoryItem item) {
    return _box.put(item.id, _toMap(item));
  }

  Map<String, dynamic> _toMap(SearchHistoryItem item) {
    final result = item.result;
    final market = result.marketSnapshot;

    return {
      'id': item.id,
      'createdAt': item.createdAt.toIso8601String(),
      'productName': result.productName,
      'detectedPrice': result.detectedPrice,
      'differencePercent': result.differencePercent,
      'status': result.status.name,
      'recommendation': result.recommendation.name,
      'isFakeDiscount': result.isFakeDiscount,
      'market': {
        'productName': market.productName,
        'averagePrice': market.averagePrice,
        'lowestPrice': market.lowestPrice,
        'highestPrice': market.highestPrice,
        'cheaperStores': market.cheaperStores,
        'previousPrice': market.previousPrice,
      },
    };
  }

  SearchHistoryItem? _fromMap(Map<dynamic, dynamic> map) {
    try {
      final market = Map<dynamic, dynamic>.from(map['market'] as Map);
      final result = PriceAnalysisResult(
        productName: map['productName'] as String,
        detectedPrice: (map['detectedPrice'] as num).toDouble(),
        marketSnapshot: MarketPriceSnapshot(
          productName: market['productName'] as String,
          averagePrice: (market['averagePrice'] as num).toDouble(),
          lowestPrice: (market['lowestPrice'] as num).toDouble(),
          highestPrice: (market['highestPrice'] as num).toDouble(),
          cheaperStores: List<String>.from(market['cheaperStores'] as List),
          previousPrice: (market['previousPrice'] as num?)?.toDouble(),
        ),
        differencePercent: (map['differencePercent'] as num).toDouble(),
        status: PriceStatus.values.byName(map['status'] as String),
        recommendation: PurchaseRecommendation.values.byName(
          map['recommendation'] as String,
        ),
        isFakeDiscount: map['isFakeDiscount'] as bool?,
      );

      return SearchHistoryItem(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        result: result,
      );
    } catch (_) {
      return null;
    }
  }
}
