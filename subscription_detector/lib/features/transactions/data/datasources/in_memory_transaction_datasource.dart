import '../../domain/entities/transaction.dart';
import 'transaction_datasource.dart';

class InMemoryTransactionDataSource implements TransactionDataSource {
  final List<Transaction> _transactions = [];

  @override
  Future<List<Transaction>> getTransactions() async {
    return List.unmodifiable(_transactions);
  }

  @override
  Future<List<Transaction>> saveTransactions(List<Transaction> transactions) async {
    _transactions.addAll(transactions);
    return List.unmodifiable(_transactions);
  }

  @override
  Future<Transaction> saveTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    return transaction;
  }
}
