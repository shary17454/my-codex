import '../../../price_analysis/domain/entities/price_analysis_result.dart';

class SearchHistoryItem {
  const SearchHistoryItem({
    required this.id,
    required this.createdAt,
    required this.result,
  });

  final String id;
  final DateTime createdAt;
  final PriceAnalysisResult result;
}
