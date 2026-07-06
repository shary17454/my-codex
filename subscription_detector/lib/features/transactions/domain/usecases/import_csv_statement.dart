import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class ImportCsvStatement {
  const ImportCsvStatement(this._repository);

  final TransactionRepository _repository;

  Future<List<Transaction>> call({
    required List<int> bytes,
    required String fileName,
  }) {
    return _repository.importCsv(bytes: bytes, fileName: fileName);
  }
}
