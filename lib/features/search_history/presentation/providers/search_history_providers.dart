import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_search_history_repository.dart';
import '../../domain/entities/search_history_item.dart';
import '../../domain/repositories/search_history_repository.dart';

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((ref) {
  return InMemorySearchHistoryRepository();
});

final searchHistoryItemsProvider = FutureProvider<List<SearchHistoryItem>>((
  ref,
) {
  return ref.watch(searchHistoryRepositoryProvider).getAll();
});
