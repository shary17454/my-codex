import '../../../subscriptions/domain/entities/subscription.dart';
import '../../domain/entities/ai_insight.dart';

abstract class AiInsightsDataSource {
  Future<AiInsight> generateInsights(List<Subscription> subscriptions);
}
