import '../../../subscriptions/domain/entities/subscription.dart';
import '../../../subscriptions/domain/entities/subscription_status.dart';
import '../../domain/entities/ai_insight.dart';
import 'ai_insights_datasource.dart';

class LocalAiInsightsDataSource implements AiInsightsDataSource {
  const LocalAiInsightsDataSource();

  @override
  Future<AiInsight> generateInsights(List<Subscription> subscriptions) async {
    final candidates = subscriptions
        .where((subscription) => subscription.status != SubscriptionStatus.likelyUsed)
        .toList()
      ..sort((a, b) => b.potentialAnnualSavings.compareTo(a.potentialAnnualSavings));

    final topCandidates = candidates.take(3).toList();
    final annualSavings = topCandidates.fold<double>(
      0,
      (sum, subscription) => sum + subscription.potentialAnnualSavings,
    );
    final monthlySavings = annualSavings / 12;

    return AiInsight(
      monthlySavings: monthlySavings,
      annualSavings: annualSavings,
      summary: _summary(subscriptions.length, monthlySavings, annualSavings),
      cancelCandidates: topCandidates,
      recommendations: const [
        'راجع الاشتراكات ذات الاستخدام غير الواضح قبل التجديد القادم.',
        'احتفظ بخدمة واحدة فقط لكل فئة ترفيهية عند تداخل الاستخدام.',
        'فعّل تذكيرًا شهريًا لمراجعة أي اشتراك جديد أو مرتفع التكلفة.',
      ],
    );
  }

  String _summary(int count, double monthlySavings, double annualSavings) {
    if (count == 0) {
      return 'لا توجد بيانات كافية بعد لتوليد ملخص مالي.';
    }
    return 'يمكن تقليل المصروفات المتكررة عبر مراجعة الاشتراكات الأقل ضرورة. التوفير المتوقع يقارب ${monthlySavings.toStringAsFixed(0)} شهريًا و${annualSavings.toStringAsFixed(0)} سنويًا.';
  }
}
