import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock_price_data_source.dart';
import '../../data/datasources/price_data_source.dart';
import '../../data/repositories/price_repository_impl.dart';
import '../../domain/repositories/price_repository.dart';
import '../../domain/usecases/analyze_price_use_case.dart';

final priceDataSourceProvider = Provider<PriceDataSource>((ref) {
  return const MockPriceDataSource();
});

final priceRepositoryProvider = Provider<PriceRepository>((ref) {
  return PriceRepositoryImpl(ref.watch(priceDataSourceProvider));
});

final analyzePriceUseCaseProvider = Provider<AnalyzePriceUseCase>((ref) {
  return AnalyzePriceUseCase(ref.watch(priceRepositoryProvider));
});
