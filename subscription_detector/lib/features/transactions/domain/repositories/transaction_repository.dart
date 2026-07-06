import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();

  Future<List<Transaction>> importCsv({
    required List<int> bytes,
    required String fileName,
  });

  Future<List<Transaction>> importPdf({
    required List<int> bytes,
    required String fileName,
  });

  Future<Transaction> addManualTransaction(Transaction transaction);
}
