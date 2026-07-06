import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/datasources/mlkit_ocr_data_source.dart';
import '../../data/datasources/open_food_facts_data_source.dart';
import '../../data/datasources/openai_product_analysis_data_source.dart';
import '../../data/datasources/product_report_local_data_source.dart';
import '../../data/repositories/product_analysis_repository_impl.dart';
import '../../data/repositories/product_ocr_repository_impl.dart';
import '../../domain/entities/product_report.dart';
import '../../domain/repositories/product_analysis_repository.dart';
import '../../domain/repositories/product_ocr_repository.dart';
import '../usecases/analyze_product.dart';
import '../usecases/extract_product_name.dart';
import '../usecases/get_cached_product_report.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('LocalStorage is provided from main.dart.');
});

final productOcrRepositoryProvider = Provider<ProductOcrRepository>((ref) {
  return ProductOcrRepositoryImpl(MlkitOcrDataSource());
});

final productAnalysisRepositoryProvider =
    Provider<ProductAnalysisRepository>((ref) {
      return ProductAnalysisRepositoryImpl(
        remoteDataSource: OpenAiProductAnalysisDataSource(DioClient.create()),
        localDataSource: ProductReportLocalDataSource(
          ref.watch(localStorageProvider),
        ),
        openFoodFactsDataSource: OpenFoodFactsDataSource(DioClient.create()),
      );
    });

final extractProductNameProvider = Provider<ExtractProductName>((ref) {
  return ExtractProductName(ref.watch(productOcrRepositoryProvider));
});

final analyzeProductProvider = Provider<AnalyzeProduct>((ref) {
  return AnalyzeProduct(ref.watch(productAnalysisRepositoryProvider));
});

final getCachedProductReportProvider = Provider<GetCachedProductReport>((ref) {
  return GetCachedProductReport(ref.watch(productAnalysisRepositoryProvider));
});

final productAnalysisControllerProvider =
    NotifierProvider<ProductAnalysisController, AsyncValue<ProductReport?>>(
      ProductAnalysisController.new,
    );

class ProductAnalysisController extends Notifier<AsyncValue<ProductReport?>> {
  @override
  AsyncValue<ProductReport?> build() {
    return const AsyncData(null);
  }

  Future<ProductReport> analyzeImage(String imagePath) async {
    state = const AsyncLoading();
    try {
      final productName = await ref
          .read(extractProductNameProvider)
          .call(imagePath);
      final report = await ref
          .read(analyzeProductProvider)
          .call(productName: productName, imagePath: imagePath);
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAnalytics.instance.logEvent(
          name: 'product_report_created',
          parameters: {
            'product_name': report.productName,
            'final_score': report.finalScore,
          },
        );
      }
      state = AsyncData(report);
      return report;
    } on AppFailure catch (error, stackTrace) {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
      state = AsyncError(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.recordError(error, stackTrace);
      }
      final failure = AppFailure(error.toString());
      state = AsyncError(failure, stackTrace);
      throw failure;
    }
  }

  Future<void> loadLatest() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(getCachedProductReportProvider).call());
  }
}
