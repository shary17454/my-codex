import '../../../subscriptions/domain/entities/subscription.dart';

class AiInsight {
  const AiInsight({
    required this.monthlySavings,
    required this.annualSavings,
    required this.summary,
    required this.cancelCandidates,
    required this.recommendations,
  });

  final double monthlySavings;
  final double annualSavings;
  final String summary;
  final List<Subscription> cancelCandidates;
  final List<String> recommendations;
}
