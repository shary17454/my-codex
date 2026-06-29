import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../price_analysis/domain/entities/price_analysis_result.dart';
import '../providers/search_history_providers.dart';

class SearchHistoryScreen extends ConsumerWidget {
  const SearchHistoryScreen({super.key});

  static const routeName = 'search-history';
  static const routePath = '/search-history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryItemsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '\u0633\u062c\u0644 '
            '\u0639\u0645\u0644\u064a\u0627\u062a '
            '\u0627\u0644\u0628\u062d\u062b',
          ),
        ),
        body: SafeArea(
          child: history.when(
            data: (items) {
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    '\u0644\u0627 \u062a\u0648\u062c\u062f '
                    '\u0639\u0645\u0644\u064a\u0627\u062a '
                    '\u0633\u0627\u0628\u0642\u0629',
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _HistoryTile(
                    productName: item.result.productName,
                    price: item.result.detectedPrice,
                    recommendation: item.result.recommendation,
                    createdAt: item.createdAt,
                  );
                },
              );
            },
            error: (error, stackTrace) {
              return Center(child: Text(error.toString()));
            },
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.productName,
    required this.price,
    required this.recommendation,
    required this.createdAt,
  });

  final String productName;
  final double price;
  final PurchaseRecommendation recommendation;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '${price.toStringAsFixed(2)} - ${_recommendationLabel(recommendation)}',
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

String _recommendationLabel(PurchaseRecommendation recommendation) {
  return switch (recommendation) {
    PurchaseRecommendation.buyNow => '\u0627\u0634\u062a\u0631\u0650 \u0627\u0644\u0622\u0646',
    PurchaseRecommendation.wait => '\u0627\u0646\u062a\u0638\u0631',
    PurchaseRecommendation.doNotBuy => '\u0644\u0627 \u062a\u0634\u062a\u0631\u0650',
  };
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
