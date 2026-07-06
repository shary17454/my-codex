import '../../../subscriptions/domain/entities/subscription.dart';
import '../entities/ai_insight.dart';

abstract class AiInsightsRepository {
  Future<AiInsight> generateInsights(List<Subscription> subscriptions);
}
