import '../../domain/entities/search_history_item.dart';
import '../../domain/repositories/search_history_repository.dart';

class InMemorySearchHistoryRepository implements SearchHistoryRepository {
  final _items = <SearchHistoryItem>[];

  @override
  Future<List<SearchHistoryItem>> getAll() async {
    return List<SearchHistoryItem>.unmodifiable(_items.reversed);
  }

  @override
  Future<void> save(SearchHistoryItem item) async {
    _items.add(item);
  }
}
