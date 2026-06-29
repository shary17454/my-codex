import '../entities/search_history_item.dart';

abstract interface class SearchHistoryRepository {
  Future<void> save(SearchHistoryItem item);

  Future<List<SearchHistoryItem>> getAll();
}
