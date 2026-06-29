import '../../domain/entities/transaction.dart';

abstract class TransactionDataSource {
  Future<List<Transaction>> getTransactions();

  Future<List<Transaction>> saveTransactions(List<Transaction> transactions);

  Future<Transaction> saveTransaction(Transaction transaction);
}
