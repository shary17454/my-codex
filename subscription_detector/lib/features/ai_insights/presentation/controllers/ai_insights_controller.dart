import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_config.dart';
import '../../../subscriptions/presentation/controllers/subscriptions_controller.dart';
import '../../data/datasources/ai_insights_datasource.dart';
import '../../data/datasources/local_ai_insights_datasource.dart';
import '../../data/datasources/openai_insights_datasource.dart';
import '../../data/repositories/ai_insights_repository_impl.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/repositories/ai_insights_repository.dart';
import '../../domain/usecases/generate_subscription_insights.dart';

final aiInsightsDataSourceProvider = Provider<AiInsightsDataSource>(
  (ref) => AppConfig.openAiApiKey.isEmpty
      ? const LocalAiInsightsDataSource()
      : OpenAiInsightsDataSource(),
);

final aiInsightsRepositoryProvider = Provider<AiInsightsRepository>(
  (ref) => AiInsightsRepositoryImpl(ref.watch(aiInsightsDataSourceProvider)),
);

final generateSubscriptionInsightsProvider = Provider(
  (ref) => GenerateSubscriptionInsights(ref.watch(aiInsightsRepositoryProvider)),
);

final aiInsightsProvider = FutureProvider<AiInsight>((ref) async {
  final subscriptions = await ref.watch(subscriptionsProvider.future);
  return ref.watch(generateSubscriptionInsightsProvider).call(subscriptions);
});
