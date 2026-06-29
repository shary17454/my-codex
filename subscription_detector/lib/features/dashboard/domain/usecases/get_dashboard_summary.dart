import '../entities/dashboard_summary.dart';
import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../subscriptions/domain/entities/subscription_status.dart';

class GetDashboardSummary {
  const GetDashboardSummary();

  DashboardSummary call(List<Subscription> subscriptions) {
    final monthlySpend = subscriptions.fold<double>(
      0,
      (sum, subscription) => sum + subscription.annualCost / 12,
    );
    final annualSpend = subscriptions.fold<double>(
      0,
      (sum, subscription) => sum + subscription.annualCost,
    );
    final forgottenCount = subscriptions
        .where((subscription) => subscription.status != SubscriptionStatus.likelyUsed)
        .length;
    final potentialSavings = subscriptions.fold<double>(
      0,
      (sum, subscription) => sum + subscription.potentialAnnualSavings,
    );

    return DashboardSummary(
      totalSubscriptions: subscriptions.length,
      monthlySpend: monthlySpend,
      annualSpend: annualSpend,
      forgottenSubscriptions: forgottenCount,
      potentialSavings: potentialSavings,
    );
  }
}
