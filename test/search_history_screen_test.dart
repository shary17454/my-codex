import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:price_detector/features/price_analysis/domain/entities/market_price_snapshot.dart';
import 'package:price_detector/features/price_analysis/domain/entities/price_analysis_result.dart';
import 'package:price_detector/features/search_history/data/repositories/in_memory_search_history_repository.dart';
import 'package:price_detector/features/search_history/domain/entities/search_history_item.dart';
import 'package:price_detector/features/search_history/presentation/providers/search_history_providers.dart';
import 'package:price_detector/features/search_history/presentation/screens/search_history_screen.dart';

void main() {
  testWidgets('shows saved search history items', (tester) async {
    final repository = InMemorySearchHistoryRepository();
    await repository.save(
      SearchHistoryItem(
        id: '1',
        createdAt: DateTime(2026, 6, 28, 10, 30),
        result: const PriceAnalysisResult(
          productName: 'Coffee Beans',
          detectedPrice: 32,
          marketSnapshot: MarketPriceSnapshot(
            productName: 'Coffee Beans',
            averagePrice: 38,
            lowestPrice: 32,
            highestPrice: 49,
            cheaperStores: ['Store A'],
            previousPrice: 36,
          ),
          differencePercent: -15.7,
          status: PriceStatus.excellent,
          recommendation: PurchaseRecommendation.buyNow,
          isFakeDiscount: null,
        ),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          searchHistoryRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SearchHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee Beans'), findsOneWidget);
    expect(find.textContaining('32.00'), findsOneWidget);
  });
}
