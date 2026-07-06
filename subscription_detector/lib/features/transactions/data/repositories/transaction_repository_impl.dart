import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/transaction_datasource.dart';
import '../parsers/csv_statement_parser.dart';
import '../parsers/pdf_statement_parser.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(
    this._dataSource,
    this._csvParser,
    this._pdfParser,
  );

  final TransactionDataSource _dataSource;
  final CsvStatementParser _csvParser;
  final PdfStatementParser _pdfParser;

  @override
  Future<Transaction> addManualTransaction(Transaction transaction) {
    return _dataSource.saveTransaction(transaction);
  }

  @override
  Future<List<Transaction>> getTransactions() {
    return _dataSource.getTransactions();
  }

  @override
  Future<List<Transaction>> importCsv({
    required List<int> bytes,
    required String fileName,
  }) {
    final transactions = _csvParser.parse(bytes);
    return _dataSource.saveTransactions(transactions);
  }

  @override
  Future<List<Transaction>> importPdf({
    required List<int> bytes,
    required String fileName,
  }) {
    final transactions = _pdfParser.parse(bytes);
    return _dataSource.saveTransactions(transactions);
  }
}
