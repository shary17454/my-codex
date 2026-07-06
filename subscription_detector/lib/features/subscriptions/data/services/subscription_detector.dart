import '../../../transactions/domain/entities/transaction.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/entities/subscription_category.dart';
import '../../domain/entities/subscription_status.dart';

class SubscriptionDetector {
  const SubscriptionDetector();

  List<Subscription> detect(List<Transaction> transactions) {
    final groups = <String, List<Transaction>>{};
    for (final transaction in transactions) {
      final key = _normalizeMerchant(transaction.merchant);
      if (key.length < 3) {
        continue;
      }
      groups.putIfAbsent(key, () => []).add(transaction);
    }

    final subscriptions = <Subscription>[];
    for (final entry in groups.entries) {
      final ordered = [...entry.value]..sort((a, b) => a.date.compareTo(b.date));
      if (ordered.length < 2) {
        continue;
      }

      final cadence = _detectCadence(ordered);
      if (cadence == null) {
        continue;
      }

      final latest = ordered.last;
      final amount = _averageAmount(ordered);
      final nextChargeDate = _nextChargeDate(latest.date, cadence);
      final annualCost = _annualCost(amount, cadence);
      final category = _categoryFor(entry.key);
      final status = _statusFor(
        chargeCount: ordered.length,
        annualCost: annualCost,
        category: category,
      );

      subscriptions.add(
        Subscription(
          id: entry.key,
          name: _displayName(latest.merchant),
          amount: amount,
          currency: latest.currency,
          nextChargeDate: nextChargeDate,
          chargeCount: ordered.length,
          annualCost: annualCost,
          status: status,
          potentialAnnualSavings:
              status == SubscriptionStatus.likelyUsed ? 0 : annualCost,
          category: category,
          cadence: cadence,
        ),
      );
    }

    subscriptions.sort((a, b) => b.potentialAnnualSavings.compareTo(a.potentialAnnualSavings));
    return subscriptions;
  }

  SubscriptionCadence? _detectCadence(List<Transaction> transactions) {
    final gaps = <int>[];
    for (var i = 1; i < transactions.length; i++) {
      gaps.add(transactions[i].date.difference(transactions[i - 1].date).inDays.abs());
    }

    final monthlyMatches = gaps.where((gap) => gap >= 25 && gap <= 35).length;
    final annualMatches = gaps.where((gap) => gap >= 335 && gap <= 395).length;

    if (monthlyMatches >= 1 || _sameDayAcrossMonths(transactions)) {
      return SubscriptionCadence.monthly;
    }
    if (annualMatches >= 1) {
      return SubscriptionCadence.annual;
    }
    if (transactions.length >= 3) {
      return SubscriptionCadence.recurring;
    }
    return null;
  }

  bool _sameDayAcrossMonths(List<Transaction> transactions) {
    if (transactions.length < 3) {
      return false;
    }
    final days = transactions.map((transaction) => transaction.date.day).toSet();
    final months = transactions.map((transaction) => transaction.date.month).toSet();
    return days.length <= 2 && months.length >= 3;
  }

  DateTime _nextChargeDate(DateTime latestDate, SubscriptionCadence cadence) {
    return switch (cadence) {
      SubscriptionCadence.monthly => DateTime(latestDate.year, latestDate.month + 1, latestDate.day),
      SubscriptionCadence.annual => DateTime(latestDate.year + 1, latestDate.month, latestDate.day),
      SubscriptionCadence.recurring => latestDate.add(const Duration(days: 30)),
    };
  }

  double _annualCost(double amount, SubscriptionCadence cadence) {
    return switch (cadence) {
      SubscriptionCadence.monthly => amount * 12,
      SubscriptionCadence.annual => amount,
      SubscriptionCadence.recurring => amount * 12,
    };
  }

  double _averageAmount(List<Transaction> transactions) {
    final total = transactions.fold<double>(0, (sum, transaction) => sum + transaction.amount);
    return total / transactions.length;
  }

  SubscriptionStatus _statusFor({
    required int chargeCount,
    required double annualCost,
    required SubscriptionCategory category,
  }) {
    if (chargeCount <= 2 || annualCost >= 1000) {
      return SubscriptionStatus.needsReview;
    }
    if (category == SubscriptionCategory.entertainment || category == SubscriptionCategory.apps) {
      return SubscriptionStatus.unnecessary;
    }
    return SubscriptionStatus.likelyUsed;
  }

  SubscriptionCategory _categoryFor(String key) {
    const entertainment = ['netflix', 'shahid', 'osn', 'disney', 'spotify', 'anghami', 'youtube'];
    const apps = ['apple', 'google', 'app store', 'play store', 'icloud'];
    const fitness = ['gym', 'fitness', 'fit', 'body', 'وقت اللياقة'];
    const digital = ['microsoft', 'adobe', 'dropbox', 'notion', 'canva', 'openai'];

    if (entertainment.any(key.contains)) {
      return SubscriptionCategory.entertainment;
    }
    if (apps.any(key.contains)) {
      return SubscriptionCategory.apps;
    }
    if (fitness.any(key.contains)) {
      return SubscriptionCategory.fitness;
    }
    if (digital.any(key.contains)) {
      return SubscriptionCategory.digitalServices;
    }
    return SubscriptionCategory.other;
  }

  String _normalizeMerchant(String merchant) {
    return merchant
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _displayName(String merchant) {
    final cleaned = merchant.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? 'Subscription' : cleaned;
  }
}
