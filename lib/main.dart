import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'features/search_history/data/repositories/hive_search_history_repository.dart';
import 'features/search_history/presentation/providers/search_history_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final searchHistoryBox = await Hive.openBox<dynamic>(
    HiveSearchHistoryRepository.boxName,
  );

  runApp(
    ProviderScope(
      overrides: [
        searchHistoryRepositoryProvider.overrideWithValue(
          HiveSearchHistoryRepository(searchHistoryBox),
        ),
      ],
      child: const PriceDetectorApp(),
    ),
  );
}
