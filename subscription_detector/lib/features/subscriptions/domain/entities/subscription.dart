import '../../../../app/config/app_config.dart';
import 'subscription_category.dart';
import 'subscription_status.dart';

enum SubscriptionCadence {
  monthly,
  annual,
  recurring,
}

class Subscription {
  const Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.nextChargeDate,
    required this.chargeCount,
    required this.annualCost,
    required this.status,
    required this.potentialAnnualSavings,
    required this.category,
    required this.cadence,
  });

  final String id;
  final String name;
  final double amount;
  final SupportedCurrency currency;
  final DateTime nextChargeDate;
  final int chargeCount;
  final double annualCost;
  final SubscriptionStatus status;
  final double potentialAnnualSavings;
  final SubscriptionCategory category;
  final SubscriptionCadence cadence;
}
