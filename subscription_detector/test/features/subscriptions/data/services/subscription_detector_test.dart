import 'package:flutter_test/flutter_test.dart';
import 'package:subscription_detector/app/config/app_config.dart';
import 'package:subscription_detector/features/subscriptions/data/services/subscription_detector.dart';
import 'package:subscription_detector/features/subscriptions/domain/entities/subscription.dart';
import 'package:subscription_detector/features/subscriptions/domain/entities/subscription_category.dart';
import 'package:subscription_detector/features/transactions/domain/entities/transaction.dart';

void main() {
  test('detects monthly entertainment subscription', () {
    const detector = SubscriptionDetector();

    final subscriptions = detector.detect([
      Transaction(
        id: '1',
        date: DateTime(2026, 1, 5),
        merchant: 'Netflix',
        amount: 39,
        currency: SupportedCurrency.sar,
      ),
      Transaction(
        id: '2',
        date: DateTime(2026, 2, 5),
        merchant: 'Netflix',
        amount: 39,
        currency: SupportedCurrency.sar,
      ),
      Transaction(
        id: '3',
        date: DateTime(2026, 3, 5),
        merchant: 'Netflix',
        amount: 39,
        currency: SupportedCurrency.sar,
      ),
    ]);

    expect(subscriptions, hasLength(1));
    expect(subscriptions.first.cadence, SubscriptionCadence.monthly);
    expect(subscriptions.first.category, SubscriptionCategory.entertainment);
    expect(subscriptions.first.annualCost, 468);
  });
}
