import '../../../subscriptions/domain/entities/subscription.dart';
import '../../domain/entities/ai_insight.dart';
import '../../domain/repositories/ai_insights_repository.dart';
import '../datasources/ai_insights_datasource.dart';

class AiInsightsRepositoryImpl implements AiInsightsRepository {
  const AiInsightsRepositoryImpl(this._dataSource);

  final AiInsightsDataSource _dataSource;

  @override
  Future<AiInsight> generateInsights(List<Subscription> subscriptions) {
    return _dataSource.generateInsights(subscriptions);
  }
}
