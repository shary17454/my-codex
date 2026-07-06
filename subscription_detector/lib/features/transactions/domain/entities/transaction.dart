import '../../../../app/config/app_config.dart';

class Transaction {
  const Transaction({
    required this.id,
    required this.date,
    required this.merchant,
    required this.amount,
    required this.currency,
    this.description,
    this.category,
  });

  final String id;
  final DateTime date;
  final String merchant;
  final double amount;
  final SupportedCurrency currency;
  final String? description;
  final String? category;
}
