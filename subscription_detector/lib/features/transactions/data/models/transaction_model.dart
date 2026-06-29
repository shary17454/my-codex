import '../../../../app/config/app_config.dart';
import '../../domain/entities/transaction.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.date,
    required this.merchant,
    required this.amount,
    required this.currencyCode,
    this.description,
    this.category,
  });

  final String id;
  final DateTime date;
  final String merchant;
  final double amount;
  final String currencyCode;
  final String? description;
  final String? category;

  Transaction toEntity() {
    return Transaction(
      id: id,
      date: date,
      merchant: merchant,
      amount: amount,
      currency: SupportedCurrency.values.firstWhere(
        (currency) => currency.code == currencyCode,
        orElse: () => AppConfig.defaultCurrency,
      ),
      description: description,
      category: category,
    );
  }

  static TransactionModel fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      date: transaction.date,
      merchant: transaction.merchant,
      amount: transaction.amount,
      currencyCode: transaction.currency.code,
      description: transaction.description,
      category: transaction.category,
    );
  }
}
