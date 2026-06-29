import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/hive_transaction_datasource.dart';
import '../../data/datasources/transaction_datasource.dart';
import '../../data/parsers/csv_statement_parser.dart';
import '../../data/parsers/pdf_statement_parser.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/add_manual_transaction.dart';
import '../../domain/usecases/get_transactions.dart';
import '../../domain/usecases/import_csv_statement.dart';
import '../../domain/usecases/import_pdf_statement.dart';

final transactionDataSourceProvider = Provider<TransactionDataSource>(
  (ref) => HiveTransactionDataSource(),
);

final csvStatementParserProvider = Provider((ref) => const CsvStatementParser());
final pdfStatementParserProvider = Provider((ref) => const PdfStatementParser());

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(transactionDataSourceProvider),
    ref.watch(csvStatementParserProvider),
    ref.watch(pdfStatementParserProvider),
  ),
);

final getTransactionsProvider = Provider(
  (ref) => GetTransactions(ref.watch(transactionRepositoryProvider)),
);

final importCsvStatementProvider = Provider(
  (ref) => ImportCsvStatement(ref.watch(transactionRepositoryProvider)),
);

final importPdfStatementProvider = Provider(
  (ref) => ImportPdfStatement(ref.watch(transactionRepositoryProvider)),
);

final addManualTransactionProvider = Provider(
  (ref) => AddManualTransaction(ref.watch(transactionRepositoryProvider)),
);

final transactionImportControllerProvider =
    AsyncNotifierProvider<TransactionImportController, List<Transaction>>(
  TransactionImportController.new,
);

class TransactionImportController extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() {
    return ref.watch(getTransactionsProvider).call();
  }

  Future<void> pickAndImportCsv() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(importCsvStatementProvider).call(
            bytes: file!.bytes!,
            fileName: file.name,
          ),
    );
  }

  Future<void> pickAndImportPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    final file = result?.files.single;
    if (file?.bytes == null) {
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(importPdfStatementProvider).call(
            bytes: file!.bytes!,
            fileName: file.name,
          ),
    );
  }

  Future<void> addManual(Transaction transaction) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(addManualTransactionProvider).call(transaction);
      return ref.read(getTransactionsProvider).call();
    });
  }
}
