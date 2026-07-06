import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class AddManualTransaction {
  const AddManualTransaction(this._repository);

  final TransactionRepository _repository;

  Future<Transaction> call(Transaction transaction) {
    return _repository.addManualTransaction(transaction);
  }
}
