import '../../../subscriptions/domain/entities/subscription.dart';
import '../entities/ai_insight.dart';
import '../repositories/ai_insights_repository.dart';

class GenerateSubscriptionInsights {
  const GenerateSubscriptionInsights(this._repository);

  final AiInsightsRepository _repository;

  Future<AiInsight> call(List<Subscription> subscriptions) {
    return _repository.generateInsights(subscriptions);
  }
}
