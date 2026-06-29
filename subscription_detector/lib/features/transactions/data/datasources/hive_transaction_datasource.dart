import 'package:hive_flutter/hive_flutter.dart';

import '../../../../app/bootstrap/app_bootstrap.dart';
import '../../../../app/config/app_config.dart';
import '../../domain/entities/transaction.dart';
import 'transaction_datasource.dart';

class HiveTransactionDataSource implements TransactionDataSource {
  HiveTransactionDataSource()
      : _box = Hive.box<Map<dynamic, dynamic>>(AppBootstrap.transactionsBoxName);

  final Box<Map<dynamic, dynamic>> _box;

  @override
  Future<List<Transaction>> getTransactions() async {
    final transactions = _box.values.map(_fromMap).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  @override
  Future<List<Transaction>> saveTransactions(List<Transaction> transactions) async {
    final entries = {
      for (final transaction in transactions) transaction.id: _toMap(transaction),
    };
    await _box.putAll(entries);
    return getTransactions();
  }

  @override
  Future<Transaction> saveTransaction(Transaction transaction) async {
    await _box.put(transaction.id, _toMap(transaction));
    return transaction;
  }

  Map<String, dynamic> _toMap(Transaction transaction) {
    return {
      'id': transaction.id,
      'date': transaction.date.toIso8601String(),
      'merchant': transaction.merchant,
      'amount': transaction.amount,
      'currency': transaction.currency.code,
      'description': transaction.description,
      'category': transaction.category,
    };
  }

  Transaction _fromMap(Map<dynamic, dynamic> map) {
    final currencyCode = map['currency']?.toString() ?? AppConfig.defaultCurrency.code;

    return Transaction(
      id: map['id'].toString(),
      date: DateTime.parse(map['date'].toString()),
      merchant: map['merchant'].toString(),
      amount: (map['amount'] as num).toDouble(),
      currency: SupportedCurrency.values.firstWhere(
        (currency) => currency.code == currencyCode,
        orElse: () => AppConfig.defaultCurrency,
      ),
      description: map['description']?.toString(),
      category: map['category']?.toString(),
    );
  }
}
