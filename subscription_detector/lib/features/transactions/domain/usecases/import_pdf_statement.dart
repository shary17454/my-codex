import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

class ImportPdfStatement {
  const ImportPdfStatement(this._repository);

  final TransactionRepository _repository;

  Future<List<Transaction>> call({
    required List<int> bytes,
    required String fileName,
  }) {
    return _repository.importPdf(bytes: bytes, fileName: fileName);
  }
}
